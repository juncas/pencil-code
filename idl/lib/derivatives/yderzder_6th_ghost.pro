;;
;;  $Id$
;;
;;  Second derivative d^2 / dy dz
;;  - 6th-order
;;  - with ghost cells
;;
function yderzder,f,ghost=ghost,bcx=bcx,bcy=bcy,bcz=bcz,param=param,t=t
  COMPILE_OPT IDL2,HIDDEN
;
  common cdat, x, y, z, mx, my, mz, nw, ntmax, date0, time0, nghostx, nghosty, nghostz
  common cdat_grid,dx_1,dy_1,dz_1,dx_tilde,dy_tilde,dz_tilde,lequidist,lperi,ldegenerated
  common cdat_coords, coord_system
;
;  Default values.
;
  default, ghost, 0
;
  if (coord_system ne 'cartesian') then $
      message, "yderzder_6th_ghost: not yet implemented for coord_system='" + coord_system + "'"
;
;  Calculate fmx, fmy, and fmz, based on the input array size.
;
  s = size(f)
  if ((s[0] lt 3) or (s[0] gt 4)) then $
      message, 'yderzder_6th_ghost: not implemented for '+strtrim(s[0],2)+'-D arrays'
  d = make_array(size=s)
  fmx = s[1] & fmy = s[2] & fmz = s[3]
  l1 = nghostx & l2 = fmx-nghostx-1
  m1 = nghosty & m2 = fmy-nghosty-1
  n1 = nghostz & n2 = fmz-nghostz-1
;
;  Check for degenerate case (no yz-derivative)
;
  if (ldegenerated[1] or ldegenerated[2] or (fmy eq 1) or (fmz eq 1)) then return, d
;
;  Calculate d2f/dydz.
;
  fac = 1./60.^2
  if (lequidist[1]) then begin
    if (fmy ne my) then $
        message, "yderzder_6th_ghost: not implemented for y-subvolumes on a non-equidistant grid in y."
    fac *= dy_1[m1]
  endif
  if (lequidist[2]) then begin
    if (fmz ne mz) then $
        message, "yderzder_6th_ghost: not implemented for z-subvolumes on a non-equidistant grid in z."
    fac *= dz_1[n1]
  endif
;
  d[l1:l2,m1:m2,n1:n2,*] = $
       (45.*fac)*( ( 45.*(f[l1:l2,m1+1:m2+1,n1+1:n2+1,*]-f[l1:l2,m1-1:m2-1,n1+1:n2+1,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1+1:n2+1,*]-f[l1:l2,m1-2:m2-2,n1+1:n2+1,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1+1:n2+1,*]-f[l1:l2,m1-3:m2-3,n1+1:n2+1,*]))  $
                  -( 45.*(f[l1:l2,m1+1:m2+1,n1-1:n2-1,*]-f[l1:l2,m1-1:m2-1,n1-1:n2-1,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1-1:n2-1,*]-f[l1:l2,m1-2:m2-2,n1-1:n2-1,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1-1:n2-1,*]-f[l1:l2,m1-3:m2-3,n1-1:n2-1,*]))) $
      - (9.*fac)*( ( 45.*(f[l1:l2,m1+1:m2+1,n1+2:n2+2,*]-f[l1:l2,m1-1:m2-1,n1+2:n2+2,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1+2:n2+2,*]-f[l1:l2,m1-2:m2-2,n1+2:n2+2,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1+2:n2+2,*]-f[l1:l2,m1-3:m2-3,n1+2:n2+2,*]))  $
                  -( 45.*(f[l1:l2,m1+1:m2+1,n1-2:n2-2,*]-f[l1:l2,m1-1:m2-1,n1-2:n2-2,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1-2:n2-2,*]-f[l1:l2,m1-2:m2-2,n1-2:n2-2,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1-2:n2-2,*]-f[l1:l2,m1-3:m2-3,n1-2:n2-2,*]))) $
      +    (fac)*( ( 45.*(f[l1:l2,m1+1:m2+1,n1+3:n2+3,*]-f[l1:l2,m1-1:m2-1,n1+3:n2+3,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1+3:n2+3,*]-f[l1:l2,m1-2:m2-2,n1+3:n2+3,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1+3:n2+3,*]-f[l1:l2,m1-3:m2-3,n1+3:n2+3,*]))  $
                  -( 45.*(f[l1:l2,m1+1:m2+1,n1-3:n2-3,*]-f[l1:l2,m1-1:m2-1,n1-3:n2-3,*])   $
                    - 9.*(f[l1:l2,m1+2:m2+2,n1-3:n2-3,*]-f[l1:l2,m1-2:m2-2,n1-3:n2-3,*])   $
                    +    (f[l1:l2,m1+3:m2+3,n1-3:n2-3,*]-f[l1:l2,m1-3:m2-3,n1-3:n2-3,*])))
;
  if (not lequidist[1]) then for m = m1, m2 do d[*,m,*,*] *= dy_1[m]
  if (not lequidist[2]) then for n = n1, n2 do d[*,*,n,*] *= dz_1[n]
;
;  Set ghost zones.
;
  if (ghost) then d=pc_setghost(d,bcx=bcx,bcy=bcy,bcz=bcz,param=param,t=t)
;
  return, d
;
end
