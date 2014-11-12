#import numpy as N
#import scipy as S

from pencil.files.ts import *
from pencil.files.dim import *
from pencil.files.pdim import *
from pencil.files.param import *
from pencil.files.grid import read_grid
from pencil.files.var import read_var
from pencil.files.index import *
from pencil.files.rrmv_par import *
from pencil.files.slices import *
from pencil.files.xyaver import *
from pencil.files.yzaver import *
from pencil.files.yaver import *
from pencil.files.zaver import *
from pencil.files.zprof import *
from pencil.files.power import *
from pencil.files.animate_interactive import *
from pencil.files.pc2vtk import *
from pencil.files.post_processing import *
try:
    from pencil.files.streamlines import *
except ImportError:
    print "streamlines not loaded (vtk pb?)"
from pencil.files.tracers import *
from pencil.files.kf import *
from pencil.files.get_format import *
from pencil.math.derivatives import *
from pencil.math.vector_multiplication import *
#from pencil.files.multi_slices import *
