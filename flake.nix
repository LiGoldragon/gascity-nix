{
  description = "Gas City — orchestration-builder SDK for multi-agent coding workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      version = "1.0.0";
      src = pkgs: pkgs.fetchFromGitHub {
        owner = "gastownhall";
        repo = "gascity";
        rev = "v${version}";
        hash = "sha256-ugH+hw0Mo/gHXdcvn06fzIEaUjdjqBOFh8g+LL8rK44=";
      };

      mkGascity = pkgs: pkgs.buildGo125Module {
        pname = "gascity";
        inherit version;
        src = src pkgs;

        vendorHash = "sha256-d1esYYBayZ6oFFGC+5/ufa0n8XXrZX5cZa0Lns+NB7s=";

        subPackages = [ "cmd/gc" ];

        ldflags = [
          "-X main.version=${version}"
          "-X main.commit=v${version}"
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
