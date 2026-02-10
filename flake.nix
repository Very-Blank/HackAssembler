{
  description = "Hackassembler flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";

    nixnvim = {
      url = "github:Very-Blank/NixNvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
  in {
    devShells."${system}".default = let
      pkgs = import nixpkgs {inherit system;};
      shell = "zsh";
    in
      pkgs.mkShell {
        packages = [
          (
            inputs.nixnvim.packages.${pkgs.stdenv.system}.default.override {
              extraConfig = {...}: {
                config = {
                  vim = {
                    # languages.zig.enable = true;
                    # languages.zig.lsp.enable = true;
                    # languages.zig.treesitter.enable = true;
                  };
                };
              };
            }
          )
          inputs.zig.packages."${system}"."0.14.1"
        ];

        shellHook = ''
          exec ${shell}
        '';
      };
  };
}
