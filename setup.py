from setuptools import setup, find_packages
from setuptools.extension import Extension

from Cython.Build import cythonize


extensions = [
    Extension(
        'acsmx2/search',
        sources=['acsmx2/search.pyx', 'clib/acsmx2.c'],
        extra_link_args=[],
        library_dirs=[],
        libraries=[],
        include_dirs=['clib'],
    ),
]


setup(
    name = 'acsmx2',
    version = '0.1',
    packages = find_packages(),
    include_package_data = True,

    entry_points = {
        'console_scripts': [
        ],
    },

    install_requires = [
        'Cython',
    ],

    ext_modules = cythonize(extensions),

    author = 'Gu Pengfei',
    author_email = 'gpfei96@gmail.com',
    description = 'A Python wrapper for acsmx2 from Snort',
    license = 'GPL-2.0',
)

