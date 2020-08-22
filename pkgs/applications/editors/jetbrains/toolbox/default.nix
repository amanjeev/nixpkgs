{ stdenv, lib, makeWrapper, patchelf, unzip, fetchurl, coreutils, gnugrep, which, libnotify, zlib, ...}:

let
  version = "1.17.7391";
  name = "jetbrains-toolbox";

in stdenv.mkDerivation {
  inherit name;
  inherit version;

  pname = name;

  src = fetchurl {
    url = "https://download.jetbrains.com/toolbox/${name}-${version}.tar.gz";
    sha256 = "6d474d55d9cee81e790f728d7801ef69f24e7685c63bbc9484e6e6c1edda29d5";
  };

  doCheck = true;


  nativeBuildInputs = [ makeWrapper patchelf unzip ];

  patchPhase = lib.optionalString (!stdenv.isDarwin) ''
      get_file_size() {
        local fname="$1"
        echo $(ls -l $fname | cut -d ' ' -f5)
      }

      munge_size_hack() {
        local fname="$1"
        local size="$2"
        strip $fname
        truncate --size=$size $fname
      }

      interpreter=$(echo ${stdenv.glibc.out}/lib/ld-linux*.so.2)
      if [ "${stdenv.hostPlatform.system}" == "x86_64-linux" ]; then
        target_size=$(get_file_size jetbrains-toolbox)
        patchelf --set-interpreter "$interpreter" jetbrains-toolbox
        munge_size_hack jetbrains-toolbox $target_size
      else
        target_size=$(get_file_size jetbrains-toolbox)
        patchelf --set-interpreter "$interpreter" jetbrains-toolbox
        munge_size_hack jetbrains-toolbox $target_size
      fi
  '';

  installPhase = ''
    mkdir -p $out/{bin,$name,share/pixmaps,libexec/${name}}
    cp -a . $out/$name
    ln -s $out/$name/${name}.png $out/share/pixmaps/${name}.png
    mv jetbrains-toolbox* $out/libexec/${name}/.


    makeWrapper "$out/$name/${name}" "$out/bin/${name}" \
      --prefix PATH : "$out/libexec/${name}:${stdenv.lib.makeBinPath [ coreutils gnugrep which ]}" \
      --prefix LD_LIBRARY_PATH : "${stdenv.lib.makeLibraryPath [
        # Some internals want libstdc++.so.6
        stdenv.cc.cc.lib
        libnotify
        zlib        
      ]}" \

    ln -s "$item/share/applications" $out/share
  '';
  

  meta = with stdenv.lib; {
    description = "Jetbrains: Manage your tools the easy way";
    longDescription = ''
      Manage your JetBrains tools easily

      * Install
      * Update automatically
      * Update the plugins together with IDE
      * Roll back and downgrade

       Save time and effort maintaining your IDEs, by downloading a patch or a
       set of patches instead of the full package download. Everything updates
       in the background while you never stop coding.
    '';
    homepage = "https://www.jetbrains.com/toolbox-app/";
    license = licenses.unfree;
    maintainers = [ maintainers.amanjeev ];
    platforms = platforms.linux;
  };
}
