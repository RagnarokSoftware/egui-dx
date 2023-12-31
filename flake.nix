{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    rust-overlay.url = "github:oxalica/rust-overlay";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    rust-overlay,
    devenv,
    fenix,
    flake-utils,
    nix-gaming,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      mkCargoCross = pkgs:
        pkgs.cargo-cross.overrideAttrs (drv: rec {
          src = pkgs.fetchFromGitHub {
            owner = "cross-rs";
            repo = "cross";
            rev = "44011c8854cb2eaac83b173cc323220ccdff18ea";
            hash = "sha256-yGYs0691CPFUX9Wg/gkm6PXCX0GnfaKDyL+BCbCUrfw=";
          };
          cargoDeps = drv.cargoDeps.overrideAttrs (pkgs.lib.const {
            inherit src;
            outputHash = "sha256-Egq2+VVl6ekReoEK2k0Esz7B/zycKQan+um+c3DhbbU=";
          });
        });
      nix-gaming-pkgs = inputs.nix-gaming.packages.${system};
    in {
      devShells = {
        default = let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [rust-overlay.overlays.default];
          };
          cargo-cross = mkCargoCross pkgs;
          toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
        in
          pkgs.mkShell {
            packages = [
              pkgs.docker
              pkgs.rustup
              cargo-cross
              toolchain
              pkgs.python3
              pkgs.freetype
              nix-gaming-pkgs.wine-ge
            ];
          };
      };
    });
}
