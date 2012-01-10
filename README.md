# Webiblo - web to ebook project

---------------------------------------

## Overview

Webiblo is a project to convert web sites to ebooks.

You can convert Getting Real web data to mobipcoket format like this.

    $ webiblo.pl http://mizzy.org/webiblo/data/Getting_Real.json


---------------------------------------

## JSON data format

JSON data format to convert web data to ebook is like this:

    {
        "title"       : "Structure and Interpretation of Computer Programs",
        "authors"     : [
            "Harold Abelson",
            "Gerald Jay Sussman",
            "Julie Sussman"
        ],
        "cover_image"   : "http://mitpress.mit.edu/sicp/full-text/book/cover.jpg",
        "content_xpath" : "//div[@class=\"content\"]", # Optional
        "exclude_xpath" : "//div[@class=\"navigation\"]", # Optional
        "chapters" : [
            {
                "title" : "Foreword",
                "uri"   : "http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-5.html#%_chap_Temp_2"
            },
            {
                "title" : "1  Building Abstractions with Procedures",
                "uri"  : "http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-9.html#%_chap_1",
                "sections" : [
                    "title" : "1.1  The Elements of Programming",
                    "uri"   : "http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-10.html#%_sec_1.1"
                    "subsections" : [
                        {
                            "title" : "1.1.1  Expressions",
                            "uri"   : "http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-10.html#%_sec_1.1.1"
                        },
                    ]
                ]
            }
        ]
    }

These are the examples.

 * http://mizzy.org/webiblo/data/Getting_Real.json
 * http://mizzy.org/webiblo/data/SICP.json

---------------------------------------

## Try your own JSON data

webiblo.pl takes JSON data from STDIN, so you can run webiblo.pl like this:

    $ cat data.json | webiblo.pl


## Share your JSON data

JSON data are put on [gh-pages branch](https://github.com/mizzy/webiblo/tree/gh-pages) and  shared on [GitHub Pages](http://mizzy.org/webiblo/).

If you create a JSON data for webiblo, please send me pull requests.

---------------------------------------

## TODO

 * Support formats other than mobipocket. (eg. EPUB3)
