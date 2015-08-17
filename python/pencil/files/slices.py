# $Id$
#
# read slice files
#
# Author: J. Oishi (joishi@amnh.org). 
# 
#
import os
import numpy as N
import pylab as P
from npfile import npfile
from param import read_param 
from dim import read_dim 
from time import sleep 

import sys

# slice file format is either
#   plane,t (old style)
#   plane,t,slice_z2pos (new style)

def read_slices(field='uu1',datadir='data/',proc=-1,
                extension='xz',format='native',oldfile=False):
    """
    read 2D slice files and return an array of (nslices,vsize,hsize).
    """
    datadir = os.path.expanduser(datadir)
    if proc < 0:
        filename = datadir+'/slice_'+field+'.'+extension
    else:
        filename = datadir+'/proc'+str(proc)+'/slice_'+field+'.'+extension

    # global dim
    param = read_param(datadir, quiet=True)

    dim = read_dim(datadir,proc) 
    if dim.precision == 'D':
        precision = 'd'
    else:
        precision = 'f'

    # set up slice plane
    if extension.startswith('xy'):
        hsize = dim.nx
        vsize = dim.ny
    if extension.startswith('xz'):
        hsize = dim.nx
        vsize = dim.nz
    if extension.startswith('yz'):
        hsize = dim.ny
        vsize = dim.nz


    infile = npfile(filename,endian=format)

    ifirst = True
    islice = 0
    t = N.zeros(1,dtype=precision)
    slices = N.zeros(1,dtype=precision)

    while 1:
        try:
            raw_data = infile.fort_read(precision)
        except ValueError:
            break
        except TypeError:
            break
        
        if oldfile:
            t = N.concatenate((t,raw_data[-1:]))
            slices = N.concatenate((slices,raw_data[:-1]))
        else:
            t = N.concatenate((t,raw_data[-2:-1]))
            slices = N.concatenate((slices,raw_data[:-2]))
        islice += 1

    output = slices[1:].reshape(islice,vsize,hsize)

    return output,t[1:]
        

def animate_slices(field='uu1',datadir='data/',proc=-1,extension='xz',format='native',
                tmin=0.,tmax=1.e38,wait=0.,amin=0.,amax=1.,transform='',oldfile=False):
    """
    read 2D slice files and assemble an animation.

    Options:

     field --- which variable to slice
     datadir --- path to data directory
     proc --- an integer giving the processor to read a slice from
     extension --- which plane of xy,xz,yz,Xz. for 2D this should be overwritten.
     format --- endian. one of little, big, or native (default)
     tmin --- start time
     tmax --- end time
     amin --- minimum value for image scaling
     amax --- maximum value for image scaling
     transform --- insert arbitrary numerical code to modify the slice
     wait --- pause in seconds between animation slices
    """
    
    datadir = os.path.expanduser(datadir)
    if proc < 0:
        filename = datadir+'/slice_'+field+'.'+extension
    else:
        filename = datadir+'/proc'+str(proc)+'/slice_'+field+'.'+extension

    # global dim
    param = read_param(datadir)

    dim = read_dim(datadir,proc) 
    if dim.precision == 'D':
        precision = 'd'
    else:
        precision = 'f'

    # set up slice plane
    if (extension == 'xy' or extension == 'Xy'):
        hsize = dim.nx
        vsize = dim.ny
    if (extension == 'xz'):
        hsize = dim.nx
        vsize = dim.nz
    if (extension == 'yz'):
        hsize = dim.ny
        vsize = dim.nz
    plane = N.zeros((vsize,hsize),dtype=precision)

    infile = npfile(filename,endian=format)

    ax = P.axes()
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_ylim

    image = P.imshow(plane,vmin=amin,vmax=amax)

    # for real-time image display
    manager = P.get_current_fig_manager()
    manager.show()

    ifirst = True
    islice = 0
    while 1:
        try:
            raw_data = infile.fort_read(precision)
        except ValueError:
            break
        except TypeError:
            break

        if oldfile:
            t = raw_data[-1]
            plane = raw_data[:-1].reshape(vsize,hsize)
        else:
            slice_z2pos = raw_data[-1]
            t = raw_data[-2]
            plane = raw_data[:-2].reshape(vsize,hsize)
        
        if transform:
            exec('plane = plane'+transform)

        if (t > tmin and t < tmax):
            title = 't = %11.3e' % t
            ax.set_title(title)
            image.set_data(plane)
            manager.canvas.draw()
            
            if ifirst:
                print "----islice----------t---------min-------max-------delta"
            print "%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,plane.min(),plane.max(),plane.max()-plane.min())
                
            ifirst = False
            islice += 1

            sleep(wait)

    infile.close()



def animate_multislices(field=['uu1'],datadir='data/',proc=-1,extension='xz',format='native',
                tmin=0.,tmax=1.e38,amin=0.,amax=1.,transform='plane[0]',
                oldfile=False,outfile=""):
    """
    read a list of 2D slice files, combine them, and assemble an animation.

    Options:

     field --- list of variables to slice
     datadir --- path to data directory
     proc --- an integer giving the processor to read a slice from
     extension --- which plane of xy,xz,yz,Xz. for 2D this should be overwritten.
     format --- endian. one of little, big, or native (default)
     tmin --- start time
     tmax --- end time
     amin --- minimum value for image scaling
     amax --- maximum value for image scaling
     transform --- insert arbitrary numerical code to combine the slices
     outfile --- if set, write the slice values in the text file
    """
    
    datadir = os.path.expanduser(datadir)
    if outfile != "":
        outslice=file(outfile,"w")
    filename=[]
    if proc < 0:
        for i in field:
            filename += [datadir+'/slice_'+i+'.'+extension]
    else:
        for i in field:
            filename += [datadir+'/proc'+str(proc)+'/slice_'+i+'.'+extension]

    # global dim
    param = read_param(datadir)

    dim = read_dim(datadir,proc) 
    if dim.precision == 'D':
        precision = 'd'
    else:
        precision = 'f'

    # set up slice plane
    if (extension == 'xy' or extension == 'Xy'):
        hsize = dim.nx
        vsize = dim.ny
    if (extension == 'xz'):
        hsize = dim.nx
        vsize = dim.nz
    if (extension == 'yz'):
        hsize = dim.ny
        vsize = dim.nz
    plane=[]
    infile=[]
    for i in filename:
        plane += [N.zeros((vsize,hsize),dtype=precision)]
        
        infile += [npfile(i,endian=format)]

    ax = P.axes()
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_ylim

    exec('plotplane ='+transform)
    image = P.imshow(plotplane,vmin=amin,vmax=amax)

    # for real-time image display
    manager = P.get_current_fig_manager()
    manager.show()

    ifirst = True
    islice = 0
    while 1:
        try:
            raw_data=[]
            for i in infile:
                raw_data += [i.fort_read(precision)]
        except ValueError:
            break
        except TypeError:
            break

        if oldfile:
            t = raw_data[0][-1]
            for i in range(len(raw_data)):
                plane[i] = raw_data[i][:-1].reshape(vsize,hsize)
        else:
            slice_z2pos = raw_data[0][-1]
            t = raw_data[0][-2]
            for i in range(len(raw_data)):
                plane[i] = raw_data[i][:-2].reshape(vsize,hsize)
        
        exec('plotplane ='+transform)

        if (t > tmin and t < tmax):
            title = 't = %11.3e' % t
            ax.set_title(title)
            image.set_data(plotplane)
            manager.canvas.draw()
            
            if ifirst:
                print "----islice----------t---------min-------max-------delta"
            print "%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,plotplane.min(),plotplane.max(),plotplane.max()-plotplane.min())
            if outfile != "":
                outslice.write("%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,plotplane.min(),plotplane.max(),plotplane.max()-plotplane.min()))
                outslice.write("\n")
               
            ifirst = False
            islice += 1

    for i in infile:
        i.close()
    if outfile != "":
        outslice.close()



def time_slices(field=['uu1'],datadir='data/',proc=-1,extension='xz',format='native',
                tmin=0.,tmax=1.e38,amin=0.,amax=1.,transform='plane[0]',dtstep=1,
                deltat=0,oldfile=False,outfile=""):
    """
    read a list of 1D slice files, combine them, and plot the slice in one dimension, and time in the other one.

    Options:

     field --- list of variables to slice
     datadir --- path to data directory
     proc --- an integer giving the processor to read a slice from
     extension --- which plane of xy,xz,yz,Xz. for 2D this should be overwritten.
     format --- endian. one of little, big, or native (default)
     tmin --- start time
     tmax --- end time
     amin --- minimum value for image scaling
     amax --- maximum value for image scaling
     transform --- insert arbitrary numerical code to combine the slices
     dtstep --- only plot every dt step
     deltat --- if set to nonzero, plot at fixed time interval rather than step
     outfile --- if set, write the slice values in the text file
    """
    
    datadir = os.path.expanduser(datadir)
    if outfile != "":
        outslice=file(outfile,"w")
    filename=[]
    if proc < 0:
        for i in field:
            filename += [datadir+'/slice_'+i+'.'+extension]
    else:
        for i in field:
            filename += [datadir+'/proc'+str(proc)+'/slice_'+i+'.'+extension]

    # global dim
    param = read_param(datadir)

    dim = read_dim(datadir,proc) 
    if dim.precision == 'D':
        precision = 'd'
    else:
        precision = 'f'

    # set up slice plane
    if (extension == 'xy' or extension == 'Xy'):
        hsize = dim.nx
        vsize = dim.ny
    if (extension == 'xz'):
        hsize = dim.nx
        vsize = dim.nz
    if (extension == 'yz'):
        hsize = dim.ny
        vsize = dim.nz
    plane=[]
    infile=[]
    for i in filename:
        plane += [N.zeros((vsize,hsize),dtype=precision)]
        
        infile += [npfile(i,endian=format)]

    ifirst = True
    islice = 0
    plotplane=[]
    dt=0
    nextt=tmin
    while 1:
        try:
            raw_data=[]
            for i in infile:
                raw_data += [i.fort_read(precision)]
        except ValueError:
            break
        except TypeError:
            break

        if oldfile:
            t = raw_data[0][-1]
            for i in range(len(raw_data)):
                plane[i] = raw_data[i][:-1].reshape(vsize,hsize)
        else:
            slice_z2pos = raw_data[0][-1]
            t = raw_data[0][-2]
            for i in range(len(raw_data)):
                plane[i] = raw_data[i][:-2].reshape(vsize,hsize)
        
        exec('tempplane ='+transform)

        if (t > tmin and t < tmax):
            if dt==0:
                plotplane += tempplane.tolist()
            
                if ifirst:
                    print "----islice----------t---------min-------max-------delta"
                print "%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,tempplane.min(),tempplane.max(),tempplane.max()-tempplane.min())
                if outfile != "":
                    outslice.write("%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,tempplane.min(),tempplane.max(),tempplane.max()-tempplane.min()))
                    outslice.write("\n")

                ifirst = False
                islice += 1
                nextt=t+deltat
            if deltat==0:
                dt=(dt+1)%dtstep
            elif t >= nextt:
                dt=0
                nextt=t+deltat
            else:
                dt=1

    ax = P.axes()
    ax.set_xlabel('t')
    ax.set_ylabel('y')
    ax.set_ylim
    image = P.imshow(N.array(plotplane).reshape(islice,vsize).transpose(),vmin=amin,vmax=amax)
    manager = P.get_current_fig_manager()
    manager.show()

    for i in infile:
        i.close()
    if outfile != "":
        outslice.close()



def make_movie(field='uu1',datadir='data/',proc=-1,extension='xz',format='native',
                tmin=0.,tmax=1.e38,amin=0.,amax=1.,transform='',oldfile=False):
    """
    read 2D slice files and assemble an animation in a mpg movie.

    Quickly written from the example at http://matplotlib.sourceforge.net/faq/howto_faq.html

    Options:

     field --- which variable to slice
     datadir --- path to data directory
     proc --- an integer giving the processor to read a slice from
     extension --- which plane of xy,xz,yz,Xz. for 2D this should be overwritten.
     format --- endian. one of little, big, or native (default)
     tmin --- start time
     tmax --- end time
     amin --- minimum value for image scaling
     amax --- maximum value for image scaling
     transform --- insert arbitrary numerical code to modify the slice
    """
    
    datadir = os.path.expanduser(datadir)
    if proc < 0:
        filename = datadir+'/slice_'+field+'.'+extension
    else:
        filename = datadir+'/proc'+str(proc)+'/slice_'+field+'.'+extension

    # global dim
    param = read_param(datadir)

    dim = read_dim(datadir,proc) 
    if dim.precision == 'D':
        precision = 'd'
    else:
        precision = 'f'

    # set up slice plane
    if (extension == 'xy' or extension == 'Xy'):
        hsize = dim.nx
        vsize = dim.ny
    if (extension == 'xz'):
        hsize = dim.nx
        vsize = dim.nz
    if (extension == 'yz'):
        hsize = dim.ny
        vsize = dim.nz
    plane = N.zeros((vsize,hsize),dtype=precision)

    infile = npfile(filename,endian=format)

    files = []
    fig = P.figure(figsize=(5,10))
    ax = fig.add_subplot(111)

    ifirst = True
    islice = 0
    while 1:
        try:
            raw_data = infile.fort_read(precision)
        except ValueError:
            break
        except TypeError:
            break

        if oldfile:
            t = raw_data[-1]
            plane = raw_data[:-1].reshape(vsize,hsize)
        else:
            slice_z2pos = raw_data[-1]
            t = raw_data[-2]
            plane = raw_data[:-2].reshape(vsize,hsize)
        
        if transform:
            exec('plane = plane'+transform)

        if (t > tmin and t < tmax):
            ax.cla()
            ax.imshow(plane,vmin=amin,vmax=amax)
            fname = '_tmp%03d.png'%islice
            print 'Saving frame', fname
            fig.savefig(fname)
            files.append(fname)
            
            if ifirst:
                print "----islice----------t---------min-------max-------delta"
            print "%10i %10.3e %10.3e %10.3e %10.3e" % (islice,t,plane.min(),plane.max(),plane.max()-plane.min())
                
            ifirst = False
            islice += 1

    print 'Making movie animation.mpg - this make take a while'
    os.system("mencoder 'mf://_tmp*.png' -mf type=png:fps=24 -ovc lavc -lavcopts vcodec=wmv2 -oac copy -o animation.mpg")
    os.system("rm _tmp*.png")
    infile.close()

