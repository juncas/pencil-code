module solid_cells_ogrid_chemistry
!
  use Cdata
  use General, only: keep_compiler_quiet
!
implicit none
!
  contains
!
    subroutine calc_pencils_chemistry_ogrid(f,p)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
      type (pencil_case) :: p
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_pencils_chemistry_ogrid
!***********************************************************************
    subroutine calc_pencils_eos_ogrid_chem(f,p)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
      type (pencil_case) :: p
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_pencils_eos_ogrid_chem
!***********************************************************************
    subroutine calc_for_chem_mixture_ogrid(f)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_for_chem_mixture_ogrid
!***********************************************************************
    subroutine dYk_dt_ogrid(f,df)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
      real, dimension (mx,my,mz,mvar) :: df
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
!
    endsubroutine dYk_dt_ogrid
!***********************************************************************
    subroutine calc_diffusion_term_ogrid(f,p)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
      type (pencil_case) :: p
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_diffusion_term_ogrid
!***********************************************************************
    subroutine calc_heatcond_chemistry_ogrid(f,df,p)
!
!   dummy routine
!
      real, dimension (mx,my,mz,mfarray) ::  f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
!
    endsubroutine calc_heatcond_chemistry_ogrid
!***********************************************************************
!
end module solid_cells_ogrid_chemistry
