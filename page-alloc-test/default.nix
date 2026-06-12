{ stdenv, lib, kernel, kernelModuleMakeFlags }:

stdenv.mkDerivation rec {
  pname = "page-alloc-test";
  version = "0.1";

  src = ./.;

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  meta = {
    description = "Check that free_pages() doesn't leak memory";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
  };
}
