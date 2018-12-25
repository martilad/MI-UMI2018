from setuptools import setup
from Cython.Build import cythonize
import numpy

setup(
    name='SATSolvers',
    version='0.1',
    ext_modules=cythonize('SAT.pyx', language_level=3),
    include_dirs=[numpy.get_include()],
    setup_requires=[
        'Cython',
        'NumPy',
    ],
    install_requires=[
        'NumPy',
    ],
)