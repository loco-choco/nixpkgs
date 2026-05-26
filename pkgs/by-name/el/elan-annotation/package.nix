{
  lib,
  fetchzip,
  jre,
  jdk,
  openjfx,
  vlc,
  alsa-lib,
  libGL,
  gtk3,
  glib,
  libX11,
  libXext,
  libXi,
  libXrender,
  libXtst,
  libXxf86vm,
  ffmpeg,
  makeWrapper,
  autoPatchelfHook,
  maven,
}:
let
  jdk' = jdk.override { enableJavaFX = true; };
in
maven.buildMavenPackage rec {
  pname = "elan-annotation";
  version = "7.1";
  src = fetchzip {
    url = "https://www.mpi.nl/tools/elan/ELAN_7-1_src.zip";
    hash = "sha256-AWkRaVXJ0MKkoSIAIrRMOe0Ed3UtSqeNLv8IOkC3avU=";
  };

  mvnHash = "sha256-21ab2m2K9zTSsgehqOQnZq6REdviI1Mlb1gpICJi/GQ=";
  mvnJdk = jdk';
  mvnParameters = "package -Dexec.phase=install -Dmaven.test.skip=true";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    jre
  ];

  runtimeDependencies = [
    ffmpeg
    vlc
  ];

  ldDependencies = [
    libGL
    gtk3
    glib
    alsa-lib
    vlc

    libX11
    libXext
    libXi
    libXrender
    libXtst
    libXxf86vm

    openjfx
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/elan
    cp -r target/lib/* $out/share/elan
    install -Dm644 target/elan-7.1.jar $out/share/elan

    runHook postInstall
  '';
  postFixup = ''
    makeWrapper ${jre}/bin/java $out/bin/elan-annotation \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath ldDependencies} \
      --prefix PATH : ${lib.makeBinPath runtimeDependencies} \
      --set GSETTINGS_SCHEMA_DIR "${gtk3}/share/gsettings-schemas/${gtk3.name}/glib-2.0/schemas"\
      --add-flags "-cp \"$out/share/elan/elan-7.1.jar:\$CLASSPATH\" mpi.eudico.client.annotator.ELAN"
  '';

  meta = {
    description = "ELAN is an annotation tool for audio and video recordings.";
    longDescription = ''
      With ELAN a user can add an unlimited number of textual annotations to audio and/or video recordings. An annotation can be a sentence, word or gloss, a comment, translation or a description of any feature observed in the media. Annotations can be created on multiple layers, called tiers. Tiers can be hierarchically interconnected. An annotation can either be time-aligned to the media or it can refer to other existing annotations. The content of annotations consists of Unicode text and annotation documents are stored in an XML format (EAF).
    '';
    homepage = "https://archive.mpi.nl/tla/elan";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.locohoco ];
    platforms = lib.platforms.all;
  };
}
