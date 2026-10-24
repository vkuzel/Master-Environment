{ pkgs, ... }:

# TODO Consider replacing with venv
let
  python = pkgs.python3.withPackages (ps: with ps; [
    pip
    setuptools
    wheel

    # Office documents and PDFs
    et-xmlfile
    olefile
    openpyxl
    pdfminer-six
    pillow
    pyocr

    # Markup and parsing
    beautifulsoup4
    chardet
    charset-normalizer
    cssselect
    html5lib
    lxml
    markdown-it-py
    markupsafe
    mdurl
    pyparsing
    pyyaml
    soupsieve
    webencodings

    # HTTP and crypto
    certifi
    cryptography
    httplib2
    idna
    oauthlib
    pyjwt
    requests
    urllib3

    # CLI
    click
    colorama
    pygments
    rich

    # Bindings
    cffi
    dbus-python
    libvirt
    pycairo
    pygobject3
    tkinter

    # Development
    coverage
    bytecode
    debugpy
    pydevd

    # Misc
    babel
    blinker
    distro
    jinja2
    launchpadlib
    lazr-restfulclient
    lazr-uri
    netaddr
    pytz
    six
    typing-extensions
    wadllib
  ]);
in
{
  home.packages = [ python ];
}
