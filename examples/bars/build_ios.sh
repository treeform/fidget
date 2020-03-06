# force a build clean every time
rm ~/.cache/nim/bars_d/*
rm ios_bars/src/*

# build it for iOS
/p/Nim/bin/nim c -f --os:ios -d:macosx -c --noMain:on --gc:none bars.nim

# copy all support files into the ios project
cp ~/.cache/nim/bars_d/*.c ios_bars/src/
cp /p/Nim/lib/nimbase.h ios_bars/src/
cp /p/glfm/glfm/src/file_compat.h ios_bars/src/
cp /p/glfm/glfm/include/glfm.h ios_bars/src/
cp /p/glfm/glfm/src/glfm_platform.h ios_bars/src/
cp /p/glfm/glfm/src/glfm_platform_ios.m ios_bars/src/
cp -r assets/* ios_bars/

cp ~/.nimble/pkgs/stb_image-2.3/stb_image/*.c ios_bars/src/
cp ~/.nimble/pkgs/stb_image-2.3/stb_image/*.h ios_bars/src/
