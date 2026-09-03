{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      server = pkgs.stdenv.mkDerivation {
        nativeBuildInputs = with pkgs; [
          makeWrapper
        ];

        buildInputs = with pkgs; [
          netcat
        ];
        name = "nix-server";
        src = ./.;
        dontBuild = true;
        installPhase = ''
          runHook preInstall

          mkdir -p $out

          mkdir -p $out/bin
          install -Dm755 server.rb $out/server.rb
          makeWrapper $out/server.rb $out/bin/server \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.netcat pkgs.ruby ]}\
            --set NIX_HTTP_BUILD_PATH $out

          mkdir -p $out/nix/
          cp -r ./nix/*.nix $out/nix/

          runHook  postInstall
        '';

        meta.mainProgram = "server";
      };

      default = inputs.self.packages.${system}.server;
    }) inputs.nixpkgs.legacyPackages;
  };
}
