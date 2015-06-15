{
    "targets": [
    {
        "target_name" : "libjulia",
        "sources" : [ "libjulia.cc" ],
        "include_dirs" : [ "/home/anton/juliasm/lib/include/" ],
        "link_settings" : {
            "libraries" : [ "-ljulia -L/home/anton/juliasm/lib/asm/", "`Magick++-config --ldflags --libs`" ],
            "library_dirs" : [ "/home/anton/juliasm/lib/asm/" ]
        },
        "cflags" : [ "-std=c++11", "-fPIC", "`Magick++-config --cppflags --cxxflags`" ]
    }
    ]
}
