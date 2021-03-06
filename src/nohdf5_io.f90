! $Id$
!
!  This module is a dummy module for non-HDF5 IO.
!  28-Oct-2016/PABoudin: coded
!
module HDF5_IO
!
  use Cdata
  use General, only: keep_compiler_quiet, itoa
  use Messages, only: fatal_error
  use Mpicomm, only: lroot
!
  implicit none
!
  interface input_hdf5
    module procedure input_hdf5_int_0D
    module procedure input_hdf5_int_1D
    module procedure input_hdf5_0D
    module procedure input_hdf5_1D
    module procedure input_hdf5_part_2D
    module procedure input_hdf5_3D
    module procedure input_hdf5_4D
  endinterface
!
  interface output_hdf5
    module procedure output_hdf5_string
    module procedure output_hdf5_int_0D
    module procedure output_hdf5_int_1D
    module procedure output_hdf5_0D
    module procedure output_hdf5_1D
    module procedure output_hdf5_part_2D
    module procedure output_hdf5_3D
    module procedure output_hdf5_4D
  endinterface
!
  include 'hdf5_io.h'
!
  private
!
  contains
!***********************************************************************
    subroutine initialize_hdf5
!
      ! nothing to do
!
    endsubroutine initialize_hdf5
!***********************************************************************
    subroutine finalize_hdf5
!
      call fatal_error ('finalize_hdf5', 'You can not use HDF5 without setting an HDF5_IO module.')
!
    endsubroutine finalize_hdf5
!***********************************************************************
    subroutine file_open_hdf5(file, truncate, global, read_only)
!
      character (len=*), intent(in) :: file
      logical, optional, intent(in) :: truncate
      logical, optional, intent(in) :: global
      logical, optional, intent(in) :: read_only
!
      call keep_compiler_quiet(file)
      call keep_compiler_quiet(.true.,truncate, global, read_only)

      call fatal_error ('file_open_hdf5', 'You can not use HDF5 without setting an HDF5_IO module.')
!
    endsubroutine file_open_hdf5
!***********************************************************************
    subroutine file_close_hdf5
!
      call fatal_error ('file_close_hdf5', 'You can not use HDF5 without setting an HDF5_IO module.')
!
    endsubroutine file_close_hdf5
!***********************************************************************
    subroutine create_group_hdf5(name)
!
      character (len=*), intent(in) :: name
!
      call keep_compiler_quiet(name)
      call fatal_error ('create_group_hdf5', 'You can not use HDF5 without setting an HDF5_IO module.')
!
    endsubroutine create_group_hdf5
!***********************************************************************
    logical function exists_in_hdf5(name)
!
      character (len=*), intent(in) :: name
!
      call keep_compiler_quiet(name)
      call fatal_error ('exists_in_hdf5', 'You can not use HDF5 without setting an HDF5_IO module.')
!
    endfunction exists_in_hdf5
!***********************************************************************
    subroutine input_hdf5_int_0D(name, data)
!
      character (len=*), intent(in) :: name
      integer, intent(out) :: data
!
      call fatal_error ('input_hdf5_int_0D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data = -1
!
    endsubroutine input_hdf5_int_0D
!***********************************************************************
    subroutine input_hdf5_int_1D(name, data, nv, same_size)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      integer, dimension (nv), intent(out) :: data
      logical, optional, intent(in) :: same_size
!
      call fatal_error ('input_hdf5_int_1D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data(:) = -1
      call keep_compiler_quiet(.true., same_size)
!
    endsubroutine input_hdf5_int_1D
!***********************************************************************
    subroutine input_hdf5_0D(name, data)
!
      character (len=*), intent(in) :: name
      real, intent(out) :: data
!
      call fatal_error ('input_hdf5_0D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data = -1.0
!
    endsubroutine input_hdf5_0D
!***********************************************************************
    subroutine input_hdf5_1D(name, data, nv, same_size)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      real, dimension (nv), intent(out) :: data
      logical, optional, intent(in) :: same_size
!
      call fatal_error ('input_hdf5_1D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data(:) = -1.0
      call keep_compiler_quiet(.true., same_size)
!
    endsubroutine input_hdf5_1D
!***********************************************************************
    subroutine input_hdf5_part_2D(name, data, mv, nc, nv)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: mv, nc
      real, dimension (mv,mparray), intent(out) :: data
      integer, intent(out) :: nv
!
      call fatal_error ('input_hdf5_part_2D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(mv)
      call keep_compiler_quiet(nc)
      data(:,:) = -1.0
      nv = -1
!
    endsubroutine input_hdf5_part_2D
!***********************************************************************
    subroutine input_hdf5_3D(name, data)
!
      character (len=*), intent(in) :: name
      real, dimension (mx,my,mz), intent(out) :: data
!
      call fatal_error ('input_hdf5_3D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data(:,:,:) = -1.0
!
    endsubroutine input_hdf5_3D
!***********************************************************************
    subroutine input_hdf5_4D(name, data, nv)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      real, dimension (mx,my,mz,nv), intent(out) :: data
!
      call fatal_error ('input_hdf5_4D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      data(:,:,:,:) = -1.0
!
    endsubroutine input_hdf5_4D
!***********************************************************************
    subroutine output_hdf5_string(name, data)
!
      character (len=*), intent(in) :: name
      character (len=*), intent(in) :: data
!
      call fatal_error ('output_hdf5_string', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name,data)
!
    endsubroutine output_hdf5_string
!***********************************************************************
    subroutine output_hdf5_int_0D(name, data)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: data
!
      call fatal_error ('output_hdf5_int_0D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
!
    endsubroutine output_hdf5_int_0D
!***********************************************************************
    subroutine output_hdf5_int_1D(name, data, nv, same_size)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      integer, dimension(nv), intent(in) :: data
      logical, optional, intent(in) :: same_size
!
      call fatal_error ('output_hdf5_int_1D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
      call keep_compiler_quiet(.true., same_size)
!
    endsubroutine output_hdf5_int_1D
!***********************************************************************
    subroutine output_hdf5_0D(name, data)
!
      character (len=*), intent(in) :: name
      real, intent(in) :: data
!
      call fatal_error ('output_hdf5_0D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
!
    endsubroutine output_hdf5_0D
!***********************************************************************
    subroutine output_hdf5_1D(name, data, nv, same_size)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      real, dimension (nv), intent(in) :: data
      logical, optional, intent(in) :: same_size
!
      call fatal_error ('output_hdf5_1D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
      call keep_compiler_quiet(.true., same_size)
!
    endsubroutine output_hdf5_1D
!***********************************************************************
    subroutine output_hdf5_part_2D(name, data, mv, nc, nv)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: mv, nc
      real, dimension (mv,mparray), intent(in) :: data
      integer, intent(in) :: nv
!
      call fatal_error ('output_hdf5_part_2D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
      call keep_compiler_quiet(mv)
      call keep_compiler_quiet(nc)
      call keep_compiler_quiet(nv)
!
    endsubroutine output_hdf5_part_2D
!***********************************************************************
    subroutine output_hdf5_3D(name, data)
!
      character (len=*), intent(in) :: name
      real, dimension (mx,my,mz), intent(in) :: data
!
      call fatal_error ('output_hdf5_3D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
!
    endsubroutine output_hdf5_3D
!***********************************************************************
    subroutine output_hdf5_4D(name, data, nv)
!
      character (len=*), intent(in) :: name
      integer, intent(in) :: nv
      real, dimension (mx,my,mz,nv), intent(in) :: data
!
      call fatal_error ('output_hdf5_4D', 'You can not use HDF5 without setting an HDF5_IO module.')
      call keep_compiler_quiet(name)
      call keep_compiler_quiet(data)
!
    endsubroutine output_hdf5_4D
!***********************************************************************
    subroutine index_append(varname,ivar,vector,array)
!
! 14-oct-18/PAB: coded
!
      character (len=*), intent(in) :: varname
      integer, intent(in) :: ivar
      integer, intent(in), optional :: vector
      integer, intent(in), optional :: array
!
      if (lroot) then
        open(3,file=trim(datadir)//'/'//trim(index_pro), POSITION='append')
        if (present (vector) .and. present (array)) then
          ! expand array: iuud => indgen(vector)
          write(3,*) trim(varname)//'=indgen('//trim(itoa(array))//')*'//trim(itoa(vector))//'+'//trim(itoa(ivar))
        else
          write(3,*) trim(varname)//'='//trim(itoa(ivar))
        endif
        close(3)
      endif
!
    endsubroutine index_append
!***********************************************************************
    subroutine particle_index_append(label,ilabel)
!
! 22-Oct-2018/PABourdin: coded
!
      character (len=*), intent(in) :: label
      integer, intent(in) :: ilabel
!
      if (lroot) then
        open(3,file=trim(datadir)//'/'//trim(particle_index_pro), POSITION='append')
        write(3,*) trim(label)//'='//trim(itoa(ilabel))
        close(3)
      endif
!
    endsubroutine particle_index_append
!***********************************************************************
    subroutine index_reset()
!
! 14-oct-18/PAB: coded
!
      if (lroot) then
        open(3,file=trim(datadir)//'/'//trim(index_pro),status='replace')
        close(3)
        open(3,file=trim(datadir)//'/'//trim(particle_index_pro),status='replace')
        close(3)
      endif
!
    endsubroutine index_reset
!***********************************************************************
endmodule HDF5_IO
