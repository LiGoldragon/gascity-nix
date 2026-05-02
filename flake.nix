{
  description = "Gas City — orchestration-builder SDK for multi-agent coding workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Tracking origin/main past v1.0.0 — v1.0.0 shipped without the
      # bd-init timeout fix (#1264) which makes `gc start` time out at
      # 30s on slow `bd config set` calls. That fix landed 2026-05-01,
      # post-tag. Bump rev when a v1.0.1+ release ships.
      version = "1.0.0-unstable-2026-05-02";
      rev = "4be4d44be6df85b1c8b7f20c4afcc98fc1713dcc";
      src = pkgs: pkgs.fetchFromGitHub {
        owner = "gastownhall";
        repo = "gascity";
        inherit rev;
        hash = "sha256-4d0seiqbwoXEeQ6CM3Y9Yuo9YWTYAFSodNcu7Tq3g6A=";
      };

      mkGascity = pkgs: pkgs.buildGo125Module {
        pname = "gascity";
        inherit version;
        src = src pkgs;

        vendorHash = "sha256-d1esYYBayZ6oFFGC+5/ufa0n8XXrZX5cZa0Lns+NB7s=";

        # Embedded pack scripts ship with `#!/bin/sh`. On NixOS that
        # resolves to mksh, which doesn't run the bash-flavored
        # gc-beads-bd.sh — the lock-acquire path silently falls into a
        # 45s wait loop and the city never comes up. Rewrite all
        # `#!/bin/sh` shebangs in embedded examples/ scripts to bash
        # before the Go embed step bakes them into the binary.
        postPatch = ''
          find examples -name '*.sh' -print0 \
            | xargs -0 sed -i '1s|^#!/bin/sh$|#!${pkgs.bash}/bin/bash|'
        '';

        subPackages = [ "cmd/gc" ];

        ldflags = [
          "-X main.version=${version}"
          "-X main.commit=${rev}"
          "-X main.date=1970-01-01T00:00:00Z"
        ];

        # The integration suite shells out to tmux/dolt/bd and expects a
        # writable HOME; skip in the sandbox. Unit tests run by upstream CI.
        doCheck = false;

        meta = with pkgs.lib; {
          description = "Orchestration-builder SDK for multi-agent coding workflows";
          homepage = "https://github.com/gastownhall/gascity";
          license = licenses.mit;
          mainProgram = "gc";
          platforms = platforms.unix;
        };
      };

      # Tools `gc` shells out to at runtime. Consumers add these to their
      # own PATH (e.g. via a devShell). They are NOT wrapped into the
      # binary so the user keeps control of versions.
      runtimeDeps = pkgs: with pkgs; [
        tmux
        git
        jq
        lsof
        procps   # pgrep
        util-linux  # flock
        dolt
        beads
      ];
    in
    {
      overlays.default = final: prev: {
        gascity = mkGascity final;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        packages = {
          default = mkGascity pkgs;
          gascity = mkGascity pkgs;
        };

        apps.default = {
          type = "app";
          program = "${mkGascity pkgs}/bin/gc";
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.go_1_25 pkgs.gopls ] ++ runtimeDeps pkgs;
        };
      });
}
