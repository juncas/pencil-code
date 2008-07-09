;; $Id: pc_read_zaver.pro,v 1.26 2008-07-09 08:26:16 ajohan Exp $
;;
;;   Read z-averages from file.
;;   Default is to only plot the data (with tvscl), not to save it in memory.
;;   The user can get the data returned in an object by specifying nit, the
;;   number of snapshots to save.
;;
pro pc_read_zaver, object=object, varfile=varfile, datadir=datadir, $
    nit=nit, iplot=iplot, min=min, max=max, zoom=zoom, $
    xax=xax, yax=yax, xtitle=xtitle, ytitle=ytitle, title=title, $
    lsubbox=lsubbox, rsubbox=rsubbox, subboxcolor=subboxcolor, tsubbox=tsubbox,$
    noaxes=noaxes, thick=thick, charsize=charsize, logplot=logplot, $
    t_title=t_title, t_scale=t_scale, t_zero=t_zero, interp=interp, $
    position=position, fillwindow=fillwindow, tformat=tformat, $
    tmin=tmin, njump=njump, ps=ps, png=png, imgdir=imgdir, noerase=noerase, $
    xsize=xsize, ysize=ysize, it1=it1, variables=variables, $
    colorbar=colorbar, bartitle=bartitle, xshift=xshift, timefix=timefix, $
    readpar=readpar, debug=debug, quiet=quiet
COMPILE_OPT IDL2,HIDDEN
COMMON pc_precision, zero, one
;;
;;  Default values.
;;
if (not keyword_set(datadir)) then datadir=pc_get_datadir()
default, varfile, 'zaverages.dat'
default, nit, 0
default, iplot, -1
default, zoom, 1
default, min, 0.0
default, max, 1.0
default, tmin, 0.0
default, njump, 0
default, ps, 0
default, png, 0
default, noerase, 0
default, imgdir, '.'
default, xsize, 10.0
default, ysize, 10.0
default, title, ''
default, t_title, 0
default, t_scale, 1.0
default, t_zero, 0.0
default, interp, 0
default, lsubbox, 0
default, rsubbox, 5
default, subboxcolor, 255
default, tsubbox, 0.0
default, thick, 1.0
default, charsize, 1.0
default, logplot, 0
default, fillwindow, 0
default, tformat, '(f5.1)'
default, it1, 10
default, variables, ''
default, colorbar, 0
default, bartitle, ''
default, xshift, 0
default, timefix, 0
default, readpar, 0
default, debug, 0
default, quiet, 0
;;
;;  Define line and character thickness (will revert to old settings later).
;;
oldthick=thick
!p.charthick=thick & !p.thick=thick & !x.thick=thick & !y.thick=thick
;
if (fillwindow) then position=[0.1,0.1,0.9,0.9]
;;
;;  Get necessary dimensions.
;;
pc_read_dim, obj=dim, datadir=datadir, /quiet
pc_set_precision, dim=dim, /quiet
;;
;;  Need to know box size for proper axes and for shifting the shearing
;;  frame.
;;
if (readpar or (xshift ne 0)) then pc_read_param, obj=par, datadir=datadir, /quiet
;;
;;  Some z-averages are erroneously calculated together with time series
;;  diagnostics. The proper time is thus found in time_series.dat.
;;
if (timefix) then pc_read_ts, obj=ts, datadir=datadir, /quiet
;;
;;  Derived dimensions.
;;
nx=dim.nx
ny=dim.ny
;;
;;  Define axes (default to indices if no axes are supplied).
;;
if (n_elements(xax) eq 0) then xax=findgen(nx)
if (n_elements(yax) eq 0) then yax=findgen(ny)
if (n_elements(par) ne 0) then begin
  x0=par.xyz0[0] & x1=par.xyz1[0] & y0=par.xyz0[1] & y1=par.xyz1[1]
  Lx=par.Lxyz[0] & Ly=par.Lxyz[1]
endif else begin
  x0=xax[0] & x1=xax[nx-1] & y0=yax[0] & y1=yax[ny-1]
  Lx=xax[nx-1]-xax[0] & Ly=yax[ny-1]-yax[0]
endelse
;;
;;  Read variables from zaver.in
;;
spawn, "echo "+datadir+" | sed -e 's/data\/*$//g'", datatopdir
spawn, 'cat '+datatopdir+'/zaver.in', allvariables
if (variables[0] eq '') then variables=allvariables
if (not quiet) then print, 'Preparing to read z-averages ', $
    arraytostring(variables,quote="'",/noleader)
nvarall=n_elements(allvariables)
nvar=n_elements(variables)
ivarpos=intarr(nvar)
;;
;;  Find the position of the requested variables in the list of all
;;  variables.
;;
for ivar=0,nvar-1 do begin
  ivarpos_est=where(variables[ivar] eq allvariables)
  if (ivarpos_est[0] eq -1) then $
      message, 'ERROR: can not find the variable '''+variables[ivar]+'''' + $
               ' in '+arraytostring(allvariables,/noleader)
  ivarpos[ivar]=ivarpos_est[0]
endfor
;;  Die if attempt to plot a variable that does not exist.
if (iplot gt nvar-1) then message, 'iplot must not be greater than nvar-1!'
;;
;;  Define arrays to put data in.
;;  The user must supply the length of the time dimension (nit).
;;
if (nit gt 0) then begin

  if (not quiet) then begin
    if (njump eq 1) then begin
      print, 'Returning averages at '+strtrim(nit,2)+' times'
    endif else begin
      print, 'Returning averages at '+strtrim(nit,2)+' times'+ $
          ' at an interval of '+strtrim(njump,2)+' steps'
    endelse
  endif

  tt=fltarr(nit/njump)*one
  for i=0,nvar-1 do begin
    cmd=variables[i]+'=fltarr(nx,ny,nit/njump)*one'
    if (execute(cmd,0) ne 1) then message, 'Error defining data arrays'
  endfor

endif
;;
;;  Variables to put single time snapshot in.
;;
array=fltarr(nx,ny,nvarall)*one
t=0.0*one
;;
;;  Prepare for read
;;
get_lun, file
filename=datadir+'/'+varfile 
if (not quiet) then print, 'Reading ', filename
dummy=findfile(filename, COUNT=countfile)
if (not countfile gt 0) then begin
  print, 'ERROR: cannot find file '+ filename
  stop
endif
close, file
openr, file, filename, /f77
;;
;; For png output, open z buffer already now.
;;
if (png) then begin
  set_plot, 'z'
  device, set_resolution=[zoom*nx,zoom*ny]
  print, 'Deleting old png files in the directory ', imgdir
  spawn, '\rm -f '+imgdir+'/img_*.png'
endif
;;
;;  Read z-averages and put in arrays if requested.
;;
it=0 & itimg=0
lwindow_opened=0
while ( not eof(file) and (nit eq 0 or it lt nit) ) do begin
;;
;;  Read time.
;;
  readu, file, t
  if (it eq 0) then t0=t
;;
;;  Read data.
;;    
  if ( (t ge tmin) and (it mod njump eq 0) ) then begin
    readu, file, array
;;
;;  Shift plane in the radial direction.
;;
    if (xshift ne 0) then begin
      for ivar=1,nvarall-1 do begin
        array[*,*,ivar]=shift(array[*,*,ivar],xshift,0)
      endfor
;;
;;  With shear we need to displace part of the plane.
;;
      if (par.Sshear ne 0.0) then begin
        dy=yax[1]-yax[0]
;;  Some z-averages are erroneously calculated together with time series
;;  diagnostics. The proper time is thus found in time_series.dat.
        if (timefix) then begin
          ii=where( abs(ts.t-t) eq min(abs(ts.t-t)) ) & ii=ii[0]
          if (ts.t[ii] ge (t-ts.dt[ii])) then ii=ii-1
          if (debug) then print, 'it, t, t_ts, dt_ts=', $
              it, t, ts.t[ii], ts.dt[ii]
          deltay=(-par.Sshear*ts.t[ii]*par.Lxyz[0]) mod par.Lxyz[1]
        endif else begin
          deltay=(-par.Sshear*t*par.Lxyz[0]) mod par.Lxyz[1]
        endelse
        deltay_int=fix(deltay/dy)
        if (debug) then print, 'it, t, deltay, deltay_int, deltay_frac', $
            it, t, deltay, deltay_int, deltay/dy-deltay_int
        for ivar=1,nvarall-1 do begin
          array2=array[*,*,ivar]
          for ix=0,xshift-1 do begin
            array2[ix,*]=shift(reform(array2[ix,*]),deltay_int)
            array2[ix,*]=pc_shift_6th(reform(array2[ix,*]),yax,deltay-deltay_int*dy)
          endfor
;;
;;  Comove with central grid point.
;;        
          for ix=0,nx-1 do begin
            array2[ix,*]=pc_shift_6th(reform(array2[ix,*]),yax,-par.Sshear*(t-t0)*xax[0])
          endfor
          array[*,*,ivar]=array2
        endfor
      endif
    endif
;;
;;  Plot requested variable (plotting is turned off by default).
;;
    if (iplot ne -1) then begin
      array_plot=array[*,*,ivarpos[iplot]]
      if (zoom ne 1.0) then begin
        array_plot=congrid(array_plot,zoom*nx,zoom*ny,/interp)
        xax=congrid(xax,zoom*nx,/interp)
        yax=congrid(yax,zoom*ny,/interp)
      endif
      if (logplot) then array_plot=alog(array_plot)
;;  Plot to post script (eps).      
      if (ps) then begin
        set_plot, 'ps'
        imgname='img_'+strtrim(string(itimg,'(i20.4)'),2)+'.eps'
        device, filename=imgdir+'/'+imgname, xsize=xsize, ysize=ysize, $
            color=1, /encapsulated, bits_per_pixel=8
        ps_fonts
        !p.font=-1
      endif else if (png) then begin
;;  Plot to png.
      endif else begin
;;  Plot to X.
        if (not noerase) then begin
          window, retain=2, xsize=zoom*nx, ysize=zoom*ny
        endif else begin
          if (not lwindow_opened) then $
              window, retain=2, xsize=zoom*nx, ysize=zoom*ny
          lwindow_opened=1
        endelse
      endelse
      sym=texsyms()
;;  Put current time in title if requested.      
      if (t_title) then $
          title='t='+strtrim(string(t/t_scale-t_zero,format=tformat),2)
;;  tvscl-type plot with axes.        
      plotimage, array_plot, $
          range=[min, max], imgxrange=[x0,x1], imgyrange=[y0,y1], $
          xtitle=xtitle, ytitle=ytitle, title=title, $
          position=position, noerase=noerase, noaxes=noaxes, $
          interp=interp, charsize=charsize, thick=thick
;;
;;  Enlargement of ``densest'' point.          
;;
      if ( lsubbox and (t ge tsubbox) ) then begin
        imax=where(array_plot eq max(array_plot))
        imax=array_indices(array_plot,imax)
        subpos=[0.7,0.7,0.9,0.9]
;;  Plot box indicating enlarged region.
        oplot, [xax[imax[0]]-rsubbox,xax[imax[0]]+rsubbox, $
                xax[imax[0]]+rsubbox,xax[imax[0]]-rsubbox, $
                xax[imax[0]]-rsubbox], $
               [yax[imax[1]]-rsubbox,yax[imax[1]]-rsubbox, $
                yax[imax[1]]+rsubbox,yax[imax[1]]+rsubbox, $
                yax[imax[1]]-rsubbox], color=subboxcolor, thick=thick
;;  Box crosses lower boundary.
        if (yax[imax[1]]-rsubbox lt y0) then begin
          oplot, [xax[imax[0]]-rsubbox,xax[imax[0]]+rsubbox, $
                  xax[imax[0]]+rsubbox,xax[imax[0]]-rsubbox, $
                  xax[imax[0]]-rsubbox], $
                 [yax[imax[1]]+Ly-rsubbox,yax[imax[1]]+Ly-rsubbox, $
                  yax[imax[1]]+Ly+rsubbox,yax[imax[1]]+Ly+rsubbox, $
                  yax[imax[1]]+Ly-rsubbox], color=subboxcolor, thick=thick
        endif
;;  Box crosses upper boundary.
        if (yax[imax[1]]+rsubbox gt y1) then begin
          oplot, [xax[imax[0]]-rsubbox,xax[imax[0]]+rsubbox, $
                  xax[imax[0]]+rsubbox,xax[imax[0]]-rsubbox, $
                  xax[imax[0]]-rsubbox], $
                 [yax[imax[1]]-Ly-rsubbox,yax[imax[1]]-Ly-rsubbox, $
                  yax[imax[1]]-Ly+rsubbox,yax[imax[1]]-Ly+rsubbox, $
                  yax[imax[1]]-Ly-rsubbox], thick=thick
        endif
;;  Subplot and box.
        if ( (xax[imax[0]]-rsubbox lt x0) or $
             (xax[imax[0]]+rsubbox gt x1) ) then begin
          array_plot=shift(array_plot,[nx/2,0])
          if (xax[imax[0]]-rsubbox lt x0) then imax[0]=imax[0]+nx/2
          if (xax[imax[0]]+rsubbox gt x1) then imax[0]=imax[0]-nx/2
        endif
        if ( (yax[imax[1]]-rsubbox lt y0) or $
             (yax[imax[1]]+rsubbox gt y1) ) then begin
          array_plot=shift(array_plot,[0,ny/2])
          if (yax[imax[1]]-rsubbox lt y0) then imax[1]=imax[1]+ny/2
          if (yax[imax[1]]+rsubbox gt y1) then imax[1]=imax[1]-ny/2
        endif
        plotimage, array_plot, $
            xrange=xax[imax[0]]+[-rsubbox,rsubbox], $
            yrange=yax[imax[1]]+[-rsubbox,rsubbox], $
            range=[min,max], imgxrange=[x0,x1], imgyrange=[y0,y1], $
            position=subpos, /noerase, /noaxes, $
            interp=interp, charsize=charsize, thick=thick
        plots, [subpos[0],subpos[2],subpos[2],subpos[0],subpos[0]], $
               [subpos[1],subpos[1],subpos[3],subpos[3],subpos[1]], /normal, $
               thick=thick, color=subboxcolor
      endif
;;  Colorbar indicating range.
      if (colorbar) then begin
        colorbar, range=[min,max], pos=[0.89,0.15,0.91,0.35], divisions=1, $
            title=bartitle, /normal, /vertical
      endif
;;  For png output, take image from z-buffer.          
      if (png) then begin
        image = tvrd()
        tvlct, red, green, blue, /get
        imgname='img_'+strtrim(string(itimg,'(i20.4)'),2)+'.png'
        write_png, imgdir+'/'+imgname, image, red, green, blue
      endif
;;  Close postscript device.      
      if (ps) then begin
        device, /close
      endif
      itimg=itimg+1
      if (ps or png and not quiet) $
          then print, 'Written image '+imgdir+'/'+imgname
    endif
;;
;;  Diagnostics.
;;
    if ( (not quiet) and (it mod it1 eq 0) ) then begin
      if (it eq 0 ) then $
          print, '  ------ it -------- t ---------- var ----- min(var) ------- max(var) ------'
      for ivar=0,nvar-1 do begin
          print, it, t, variables[ivar], $
              min(array[*,*,ivarpos[ivar]]), max(array[*,*,ivarpos[ivar]]), $
              format='(i11,f15.7,A12,2e17.7)'
      endfor
    endif
;;
;;  Split read data into named arrays.
;;
    if ( it le nit-1 ) then begin
      tt[it/njump]=t
      for ivar=0,nvar-1 do begin
        cmd=variables[ivar]+'[*,*,it/njump]=array[*,*,ivarpos[ivar]]'
        if (execute(cmd,0) ne 1) then message, 'Error putting data in array'
      endfor
    endif
  endif else begin
    readu, file, dummy
  endelse
;;
    it=it+1
;;
endwhile
;;
;;  Revert to old settings for line and character thickness.
;;
thick=oldthick
!p.charthick=thick & !p.thick=thick & !x.thick=thick & !y.thick=thick
;;
;;  Put data in structure. One must set nit>0 to specify how many lines
;;  of data that should be saved.
;;
if (nit ne 0) then begin
  makeobject="object = create_struct(name=objectname,['t'," + $
      arraytostring(variables,quote="'",/noleader) + "],"+"tt[0:it/njump-1],"+$
      arraytostring(variables+'[*,*,0:it/njump-1]',/noleader) + ")"
;
  if (execute(makeobject) ne 1) then begin
    message, 'ERROR evaluating variables: ' + makeobject, /info
    undefine,object
  endif
endif
;
end
