# force a build clean every time
rm ~/.cache/nim/bars_d/*
rm android_bars/app/src/main/cpp/*

/p/Nim/bin/nim c -f --cpu:arm --os:android -c -d:androidNDK --noMain:on bars.nim

cp android_bars/CMakeLists.txt android_bars/app/src/main/cpp/

cp ~/.cache/nim/bars_d/*.c android_bars/app/src/main/cpp/

cp /p/Nim/lib/nimbase.h android_bars/app/src/main/cpp/
cp /p/glfm/glfm/src/file_compat.h android_bars/app/src/main/cpp/
cp /p/glfm/glfm/include/glfm.h android_bars/app/src/main/cpp/
cp /p/glfm/glfm/src/glfm_platform.h android_bars/app/src/main/cpp/
cp /p/glfm/glfm/src/glfm_platform_android.c android_bars/app/src/main/cpp/

cp -r assets/* android_bars/app/src/main/assets

cp ~/.nimble/pkgs/stb_image-2.3/stb_image/*.c android_bars/app/src/main/cpp/
cp ~/.nimble/pkgs/stb_image-2.3/stb_image/*.h android_bars/app/src/main/cpp/