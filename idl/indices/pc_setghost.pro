;;
;;  Performs a periodic shift in the y-direction of an entire y-z plane by
;;  the amount shift_y. The shift is done in Fourier space for maximum
;;  interpolation accuracy.
;;
;;  Author : Anders Johansen
;;  Date   : 06/06/2008
;;
function fourier_shift_yz_y, plane_yz, deltay, Ly
;
ny=n_elements(plane_yz[*,0])
nz=n_elements(plane_yz[0,*])
;
;  Define wavenumbers based on the Nyquist frequency.
;
k0=2*!dpi/Ly
ky_fft=k0*double([indgen(ny/2+1),-reverse(indgen(ny/2-1)+1)])
;
;  Complex shift array.
;
cmplx_shift=exp(complex(0.0d,-ky_fft*deltay))
;
;  Fourier transform along y.
;
plane_yz_ky=fft(plane_yz,dim=1)
;
;  Shift plane in Fourier space.
;
plane_yz_ky=plane_yz_ky*spread(cmplx_shift,1,nz)
;
;  Transform back to real space.
;
plane_yz =fft(plane_yz_ky,dim=1,/inverse)
;
return, plane_yz
;
end
;;
;;  Set ghost zones.
;;  Currently, only a subset of periodic boundary conditions are prepared.
;;
function pc_setghost, f, bcx=bcx, bcy=bcy, bcz=bcz, debug=debug, $
    deltay=deltay, Ly=Ly
;
default, bcx, 'p'
default, bcy, 'p'
default, bcz, 'p'
;
s=size(f)
if (s[0] lt 3) then begin
  print, 'error: pc_setghost only works with 3-D or 4-D arrays - returning.'
  return, f
endif
;
mx=s[1] & my=s[2] & mz=s[3]
nghost=3
l1=nghost & l2=mx-nghost-1
m1=nghost & m2=my-nghost-1
n1=nghost & n2=mz-nghost-1
;
;  Debug output.
;
if (keyword_set(debug)) then begin
  help, f
  print, 'mx, my, mz=', mx, my, mz
  print, 'l1, l2, m1, m2, n1, n2=', l1, l2, m1, m2, n1, n2
endif
;
;  Set ghost zones in x-direction.
;
if (bcx eq 'p') then begin
  f[   0:l1-1,*,*,*]=f[l2-2:l2  ,*,*,*]
  f[l2+1:mx-1,*,*,*]=f[  l1:l1+2,*,*,*]
endif else if (bcx eq 'she') then begin
  f[   0:l1-1,*,*,*]=f[l2-2:l2  ,*,*,*]
  f[l2+1:mx-1,*,*,*]=f[  l1:l1+2,*,*,*]
  for ix=1,3 do begin
    plane_yz=reform(f[l1-ix,m1:m2,n1:n2,*])
    plane_yz=fourier_shift_yz_y(plane_yz,deltay mod Ly,Ly)
    f[l1-ix,m1:m2,n1:n2,*]=plane_yz
    plane_yz=reform(f[l2+ix,m1:m2,n1:n2,*])
    plane_yz=fourier_shift_yz_y(plane_yz,-(deltay mod Ly),Ly)
    f[l2+ix,m1:m2,n1:n2,*]=plane_yz
  endfor
endif else begin
  print, 'Boundary condition bcx=', bcx, ' is not implemented - returning'
  return, f
endelse
;
;  Set ghost zones in y-direction.
;
if (bcy eq 'p') then begin
  f[*,   0:m1-1,*,*]=f[*,m2-2:m2  ,*,*]
  f[*,m2+1:my-1,*,*]=f[*,  m1:m1+2,*,*]
endif else begin
  print, 'Boundary condition bcy=', bcy, ' is not implemented - returning'
  return, f
endelse
;
;  Set ghost zones in z-direction.
;
if (bcz eq 'p') then begin
  f[*,*,   0:n1-1,*]=f[*,*,n2-2:n2  ,*]
  f[*,*,n2+1:mz-1,*]=f[*,*,  n1:n1+2,*]
endif else begin
  print, 'Boundary condition bcz=', bcz, ' is not implemented'
  return, f
endelse
;
return, f
;
end
;
