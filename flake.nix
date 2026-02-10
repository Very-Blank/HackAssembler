{
  description = "Hackassembler flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
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
          inputs.zig.packages."${system}"."0.14.1"
        ];

        shellHook = ''
          exec ${shell}
        '';
      };
  };
}
