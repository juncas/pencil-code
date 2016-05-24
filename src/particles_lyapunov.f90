! $Id$
!
!  This module writes information about the local state of the gas at
!  the positions of a selected number of particles.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
!
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lparticles_lyapunov=.true.
!
! MAUX CONTRIBUTION 9
! MPVAR CONTRIBUTION 13
!
!***************************************************************
module Particles_lyapunov
!
  use Cdata
  use Messages
  use Particles_cdata
  use Particles_map
  use Particles_mpicomm
!
  implicit none
!
  include 'particles_lyapunov.h'
!
  logical :: lnoise2pvector=.false.
  real :: fake_eta=0.,bamp=0.
  integer :: idiag_bx2pm=0,idiag_by2pm=0,idiag_bz2pm=0
!
  namelist /particles_lyapunov_init_pars/ &
    bamp
!
  namelist /particles_lyapunov_run_pars/ &
  lnoise2pvector,fake_eta
!
  contains
!***********************************************************************
    subroutine register_particles_lyapunov()
!
!  Set up indices for access to the fp and dfp arrays
!
!  May-16/dhruba: coded
!
      use FArrayManager, only: farray_register_auxiliary
!
      if (lroot) call svn_id( &
          "$Id$")
!
!  Indices for velocity gradient matrix (Wij) at particle positions
!
      iup11=npvar+1
      pvarname(npvar+1)='iup11'
      iup12=npvar+2
      pvarname(npvar+2)='iup12'
      iup13=npvar+3
      pvarname(npvar+3)='iup13'
      iup21=npvar+4
      pvarname(npvar+4)='iup21'
      iup22=npvar+5
      pvarname(npvar+5)='iup22'
      iup23=npvar+6
      pvarname(npvar+6)='iup23'
      iup31=npvar+7
      pvarname(npvar+7)='iup31'
      iup32=npvar+8
      pvarname(npvar+8)='iup32'
      iup33=npvar+9
      pvarname(npvar+9)='iup33'
!
!  Indices for a passive vector at particle positions
!
      ibpx=npvar+10
      pvarname(npvar+10)='ibpx'
      ibpy=npvar+11
      pvarname(npvar+11)='ibpy'
      ibpz=npvar+12
      pvarname(npvar+12)='ibpz'
!
! An unique index to particles 
!
      ipindex=npvar+13
      pvarname(npvar+13) = 'ipindex'
!
!  Increase npvar accordingly.
!
      npvar=npvar+13
!
!  Set indices for velocity gradient matrix at grid points
!
      call farray_register_auxiliary('guij',iguij,communicated=.true.,vector=9)
      igu11=iguij; igu12=iguij+1; igu13=iguij+2
      igu21=iguij+3; igu22=iguij+4; igu23=iguij+5
      igu31=iguij+6; igu32=iguij+7; igu33=iguij+8
!
!  Check that the fp and dfp arrays are big enough.
!
      if (npvar > mpvar) then
        if (lroot) write(0,*) 'npvar = ', npvar, ', mpvar = ', mpvar
        call fatal_error('register_particles','npvar > mpvar')
      endif
!
    endsubroutine register_particles_lyapunov
!***********************************************************************
    subroutine initialize_particles_lyapunov(f)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  13-nov-07/anders: coded
!
      use General, only: keep_compiler_quiet
      use FArrayManager
!
      real, dimension (mx,my,mz,mfarray) :: f
!
!  Stop if there is no velocity to calculate derivatives
!
      if (.not. (lhydro.or.lhydro_kinematic)) &
        call fatal_error('initialize_particles_lyapunov','you must select either hydro or hydro_kinematic')
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_particles_lyapunov
!***********************************************************************
    subroutine init_particles_lyapunov(f,fp)
!
      use Sub, only: kronecker_delta
      use General, only: keep_compiler_quiet,random_number_wrapper
      use Mpicomm, only:  mpiallreduce_sum_int
      real, dimension (mx,my,mz,mfarray), intent (in) :: f
      real, dimension (mpar_loc,mparray), intent (out) :: fp
      real, dimension(nx,3:3) :: uij 
      integer, dimension (ncpus) :: my_particles=0,all_particles=0
      real :: random_number
      integer :: ipzero,ik,ii,jj,ij
!
!
      my_particles(iproc+1) = npar_loc
      call  mpiallreduce_sum_int(my_particles,all_particles,ncpus)
      if (iproc.eq.0) then
        ipzero=0
      else
        ipzero=sum(all_particles(1:iproc))
      endif
      do ip=1,npar_loc
!
! Go over the particles and assign them an unique index. This index must
! be unique among processors.
!
        fp(ip,ipindex)= real(ipzero+ip)
!
! Initialize the gradU matrix at particle position by interpolating from 
! grid points. The initial condition is kroner delta.
!
        ij=0
        do ii=1,3; do jj=1,3 
          ij=ij+1
          fp(ip,iup11+ij)=kronecker_delta(ii,jj)
        enddo;enddo
!
! Assign random initial value for the passive vector 
!
        do ik=1,3
          call random_number_wrapper(random_number)
          fp(ip,ibpx+ik-1)= random_number
        enddo
      enddo
!
    endsubroutine init_particles_lyapunov
!***********************************************************************
    subroutine dlyapunov_dt(f,df,fp,dfp,ineargrid)
!
!
      use Diagnostics
      use Particles_sub, only: sum_par_name
!
      real, dimension (mx,my,mz,mfarray), intent (in) :: f
      real, dimension (mx,my,mz,mvar), intent (inout) :: df
      real, dimension (mpar_loc,mparray), intent (in) :: fp
      real, dimension (mpar_loc,mpvar), intent (inout) :: dfp
      integer, dimension (mpar_loc,3), intent (in) :: ineargrid
      logical :: lheader, lfirstcall=.true.
!
!  Print out header information in first time step.
!
      lheader=lfirstcall .and. lroot
      if (lheader) then
        print*,'dlyapunov_dt: Calculate dlyapunov_dt'
      endif
!
      if (ldiagnos) then
        if (idiag_bx2pm/=0) then 
          call sum_par_name(fp(1:npar_loc,ibpx)*fp(1:npar_loc,ibpx),idiag_bx2pm)
        endif
        if (idiag_by2pm/=0) then 
          call sum_par_name(fp(1:npar_loc,ibpy)*fp(1:npar_loc,ibpy),idiag_by2pm)
        endif
        if (idiag_bz2pm/=0) then 
          call sum_par_name(fp(1:npar_loc,ibpz)*fp(1:npar_loc,ibpz),idiag_bz2pm)
        endif
      endif
!
      if (lfirstcall) lfirstcall=.false.
!
    endsubroutine dlyapunov_dt
!***********************************************************************
    subroutine dlyapunov_dt_pencil(f,df,fp,dfp,p,ineargrid)
!
      use Sub, only: linarray2matrix,matrix2linarray
!
      real, dimension (mx,my,mz,mfarray),intent(in) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
      real, dimension (mpar_loc,mparray), intent(in) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
      intent (inout) :: df, dfp,ineargrid
      real, dimension(3) :: Bp,dBp
      real, dimension(9) :: Sij_lin,Wij_lin,dWij_lin
      real, dimension(3,3) :: Sijp,Wijp,dWijp
      integer :: ix0,iy0,iz0,i,j,ij,k
!
!  Identify module.
!
      if (headtt) then
        if (lroot) print*,'dlyapunov_dt_pencil: calculate dlyapunov_dt'
      endif
!
      if (npar_imn(imn)/=0) then
!
!  Loop over all particles in current pencil.
!
        do k=k1_imn(imn),k2_imn(imn)
!
          ix0=ineargrid(k,1)
          iy0=ineargrid(k,2)
          iz0=ineargrid(k,3)
!
!  interpolate the gradu matrix to particle positions
!
          call interpolate_linear(f,igu11,igu33,fp(k,ixp:izp),Sij_lin,ineargrid(k,:), &
            0,ipar(k))
          call linarray2matrix(Sij_lin,Sijp)
!
! solve (d/dt)W_ij = S_ik W_kj
!
          Wij_lin = fp(k,iup11:iup33)
          call linarray2matrix(Wij_lin,Wijp)
          dWijp=matmul(Sijp,Wijp)
          call matrix2linarray(dWijp,dWij_lin)
          dfp(k,iup11:iup33)= dfp(k,iup11:iup33)+dWij_lin
!
! solve (d/dt) B_i = S_ik B_k 
!
          Bp=fp(k,ibpx:ibpz)
          dBp=matmul(Sijp,Bp)
          dfp(k,ibpx:ibpz)=dfp(k,ibpx:ibpz)+dBp
        enddo
      endif
!
    endsubroutine dlyapunov_dt_pencil
!***********************************************************************
    subroutine read_plyapunov_init_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=particles_lyapunov_init_pars, IOSTAT=iostat)
!
    endsubroutine read_plyapunov_init_pars
!***********************************************************************
    subroutine write_plyapunov_init_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=particles_lyapunov_init_pars)
!
    endsubroutine write_plyapunov_init_pars
!***********************************************************************
    subroutine read_plyapunov_run_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=particles_lyapunov_run_pars, IOSTAT=iostat)
!
    endsubroutine read_plyapunov_run_pars
!***********************************************************************
    subroutine write_plyapunov_run_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=particles_lyapunov_run_pars)
!
    endsubroutine write_plyapunov_run_pars
!***********************************************************************
    subroutine particles_stochastic_lyapunov(fp)
      use General,only : gaunoise_number
      real, dimension (mpar_loc,mparray), intent(inout) :: fp
      integer :: ip,ik
      real,dimension(2) :: grandom
      do ik=1,3
        do ip=1,npar_loc/2
          call gaunoise_number(grandom)
          fp(2*ip-1,ibpx+ik-1) = sqrt(fake_eta)*grandom(2)*sqrt(dt)
          fp(2*ip,ibpx+ik-1) = sqrt(fake_eta)*grandom(1)*sqrt(dt)
        enddo
        if (modulo(npar_loc,2).ne.0) then
          call gaunoise_number(grandom)
          fp(npar_loc,ibpx+ik-1) = sqrt(fake_eta)*grandom(1)*sqrt(dt)
        endif
      enddo
!    
    endsubroutine particles_stochastic_lyapunov
!***********************************************************************
    subroutine rprint_particles_lyapunov(lreset,lwrite)
!
!  Read and register print parameters relevant for particles.
!
!  may-2016/dhruba+akshay: coded
!
      use Diagnostics
      use General,   only: itoa
!
      logical :: lreset
      logical, optional :: lwrite
!
      integer :: iname,inamez,inamey,inamex,inamexy,inamexz,inamer,inamerz
      integer :: k
      logical :: lwr
      character (len=intlen) :: srad
!
!  Write information to index.pro.
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
      if (lwr) then
        write(3,*) 'iup11=',iup11
        write(3,*) 'iup12=',iup12
        write(3,*) 'iup13=',iup13
        write(3,*) 'iup21=',iup21
        write(3,*) 'iup22=',iup22
        write(3,*) 'iup23=',iup23
        write(3,*) 'iup31=',iup31
        write(3,*) 'iup32=',iup32
        write(3,*) 'iup33=',iup33
        write(3,*) 'ibpx=', ibpx
        write(3,*) 'ibpy=', ibpy
        write(3,*) 'ibpz=', ibpz
        write(3,*) 'ipindex=', ipindex
      endif
!
!  Reset everything in case of reset.
!
      if (lreset) then
        idiag_bx2pm=0;idiag_by2pm=0;idiag_bz2pm=0
      endif
!
!  Run through all possible names that may be listed in print.in.
!
      if (lroot .and. ip<14) print*,'rprint_particles: run through parse list'
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'bx2pm',idiag_bx2pm)
        call parse_name(iname,cname(iname),cform(iname),'by2pm',idiag_by2pm)
        call parse_name(iname,cname(iname),cform(iname),'bz2pm',idiag_bz2pm)
      enddo
!
    endsubroutine rprint_particles_lyapunov
!***********************************************************************
endmodule Particles_lyapunov
