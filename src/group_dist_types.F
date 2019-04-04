!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2019  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Types to describe group distributions
!> \par History
!>       2019.03 created [Frederick Stein]
!> \author Frederick Stein
! **************************************************************************************************
MODULE group_dist_types
   USE cp_para_types,                   ONLY: cp_para_env_type
   USE message_passing,                 ONLY: mp_sum
   USE util,                            ONLY: get_limit
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'group_dist_types'

   PUBLIC :: group_dist_d0_type, group_dist_d1_type, &
             create_group_dist, get_group_dist, release_group_dist

   ! Type to represent start, end and size of one group (usually the own group)
   ! The underscore is added to prevent confusions with fortran intrinsics
   TYPE group_dist_d0_type
      INTEGER :: starts, ends, sizes
   END TYPE group_dist_d0_type

   ! Class to represent 1d-sets of starts, ends and sizes of all groups
   ! Better for exchanging information than using arrays of group_dist_d0_type
   TYPE group_dist_d1_type
      INTEGER, ALLOCATABLE, DIMENSION(:) :: starts, ends, sizes
   END TYPE group_dist_d1_type
   
   INTERFACE create_group_dist
      MODULE PROCEDURE create_group_dist_d0, &
                       create_group_dist_d1_i1, &
                       create_group_dist_d1_i3, &
                       create_group_dist_d1_gd, &
                       create_group_dist_d1_0
   END INTERFACE create_group_dist
   
   INTERFACE get_group_dist
      MODULE PROCEDURE get_group_dist_d0, &
                       get_group_dist_d1, &
                       get_group_dist_gd1
   END INTERFACE
   
   INTERFACE release_group_dist
      MODULE PROCEDURE release_group_dist_d1
   END INTERFACE release_group_dist

CONTAINS

   PURE SUBROUTINE create_group_dist_d0(this, ngroups, dimen, pos)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this
      INTEGER, INTENT(IN)                   :: ngroups, dimen, pos

      CHARACTER(LEN=*), PARAMETER :: routineN = 'create_group_dist_d0', routineP = moduleN//':'//routineN
   
      INTEGER, DIMENSION(2) :: itmp
      
      itmp = get_limit(dimen, ngroups, pos)
      this%starts = itmp(1)
      this%ends = itmp(2)
      this%sizes = itmp(2)-itmp(1)+1
      
   END SUBROUTINE create_group_dist_d0

   PURE SUBROUTINE create_group_dist_d1_i1(this, ngroups, dimen)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this
      INTEGER, INTENT(IN)                   :: ngroups, dimen

      CHARACTER(LEN=*), PARAMETER :: routineN = 'create_group_dist_d1_i1', routineP = moduleN//':'//routineN
   
      INTEGER :: iproc
      INTEGER, DIMENSION(2) :: itmp
      
      ALLOCATE(this%starts(0:ngroups-1))
      this%starts = 0
      ALLOCATE(this%ends(0:ngroups-1))
      this%ends = 0
      ALLOCATE(this%sizes(0:ngroups-1))
      this%sizes = 0

      DO iproc = 0, ngroups-1
         itmp = get_limit(dimen, ngroups, iproc)
         this%starts(iproc) = itmp(1)
         this%ends(iproc) = itmp(2)
         this%sizes(iproc) = itmp(2)-itmp(1)+1
      END DO
      
   END SUBROUTINE create_group_dist_d1_i1

   PURE SUBROUTINE create_group_dist_d1_0(this, ngroups)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this
      INTEGER, INTENT(IN)                   :: ngroups

      CHARACTER(LEN=*), PARAMETER :: routineN = 'create_group_dist_d1_0', routineP = moduleN//':'//routineN
      
      ALLOCATE(this%starts(0:ngroups-1))
      this%starts = 0
      ALLOCATE(this%ends(0:ngroups-1))
      this%ends = 0
      ALLOCATE(this%sizes(0:ngroups-1))
      this%sizes = 0
      
   END SUBROUTINE create_group_dist_d1_0

   SUBROUTINE create_group_dist_d1_i3(this, starts, ends, sizes, para_env)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this
      INTEGER, INTENT(IN)                   :: starts, ends, sizes
      TYPE(cp_para_env_type), POINTER       :: para_env

      CHARACTER(LEN=*), PARAMETER :: routineN = 'create_group_dist_d1_i3', routineP = moduleN//':'//routineN
      
      INTEGER :: handle
      
      CALL timeset(routineN, handle)
      
      ALLOCATE(this%starts(0:para_env%num_pe-1))
      this%starts = 0
      ALLOCATE(this%ends(0:para_env%num_pe-1))
      this%ends = 0
      ALLOCATE(this%sizes(0:para_env%num_pe-1))
      this%sizes = 0

      this%starts(para_env%mepos) = starts
      this%ends(para_env%mepos) = ends
      this%sizes(para_env%mepos) = sizes
      
      CALL mp_sum(this%starts, para_env%group)
      CALL mp_sum(this%ends, para_env%group)
      CALL mp_sum(this%sizes, para_env%group)
      
      CALL timestop(handle)
      
   END SUBROUTINE create_group_dist_d1_i3

   SUBROUTINE create_group_dist_d1_gd(this, group_dist_ext, para_env)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this
      TYPE(group_dist_d0_type), INTENT(IN)  :: group_dist_ext
      TYPE(cp_para_env_type), POINTER       :: para_env

      CHARACTER(LEN=*), PARAMETER :: routineN = 'create_group_dist_d1_gd', routineP = moduleN//':'//routineN
      
      INTEGER :: handle
      
      CALL timeset(routineN, handle)
      
      ALLOCATE(this%starts(0:para_env%num_pe-1))
      this%starts = 0
      ALLOCATE(this%ends(0:para_env%num_pe-1))
      this%ends = 0
      ALLOCATE(this%sizes(0:para_env%num_pe-1))
      this%sizes = 0

      this%starts(para_env%mepos) = group_dist_ext%starts
      this%ends(para_env%mepos) = group_dist_ext%ends
      this%sizes(para_env%mepos) = group_dist_ext%sizes
      
      CALL mp_sum(this%starts, para_env%group)
      CALL mp_sum(this%ends, para_env%group)
      CALL mp_sum(this%sizes, para_env%group)
      
      CALL timestop(handle)
      
   END SUBROUTINE create_group_dist_d1_gd

   PURE SUBROUTINE get_group_dist_d0(this, starts, ends, sizes)
      TYPE(group_dist_d0_type), INTENT(IN) :: this
      INTEGER, INTENT(OUT), OPTIONAL       :: starts, ends, sizes

      CHARACTER(LEN=*), PARAMETER :: routineN = 'get_group_dist_d0', routineP = moduleN//':'//routineN

      IF (PRESENT(starts)) starts = this%starts
      IF (PRESENT(ends)) ends = this%ends
      IF (PRESENT(sizes)) sizes = this%sizes
      
   END SUBROUTINE get_group_dist_d0

   PURE SUBROUTINE get_group_dist_d1(this, pos, starts, ends, sizes, group_dist_ext)
      TYPE(group_dist_d1_type), INTENT(IN) :: this
      INTEGER, INTENT(IN)                  :: pos
      INTEGER, INTENT(OUT), OPTIONAL       :: starts, ends, sizes
      TYPE(group_dist_d0_type), INTENT(OUT), OPTIONAL :: group_dist_ext

      CHARACTER(LEN=*), PARAMETER :: routineN = 'get_group_dist_d1', routineP = moduleN//':'//routineN

      IF (PRESENT(starts)) starts = this%starts(pos)
      IF (PRESENT(ends)) ends = this%ends(pos)
      IF (PRESENT(sizes)) sizes = this%sizes(pos)
      
      IF(PRESENT(group_dist_ext)) THEN
         group_dist_ext%starts = this%starts(pos)
         group_dist_ext%ends = this%ends(pos)
         group_dist_ext%sizes = this%sizes(pos)
      END IF
      
   END SUBROUTINE get_group_dist_d1

   PURE SUBROUTINE get_group_dist_gd1(this, pos, group_dist_ext, pos_ext)
      TYPE(group_dist_d1_type), INTENT(IN) :: this
      INTEGER, INTENT(IN)                  :: pos, pos_ext
      TYPE(group_dist_d1_type), INTENT(INOUT) :: group_dist_ext

      CHARACTER(LEN=*), PARAMETER :: routineN = 'get_group_dist_gd1', routineP = moduleN//':'//routineN

      group_dist_ext%starts(pos_ext) = this%starts(pos)
      group_dist_ext%ends(pos_ext) = this%ends(pos)
      group_dist_ext%sizes(pos_ext) = this%sizes(pos)
      
   END SUBROUTINE get_group_dist_gd1

   PURE SUBROUTINE release_group_dist_d1(this)
      TYPE(group_dist_d1_type), INTENT(INOUT) :: this

      CHARACTER(LEN=*), PARAMETER :: routineN = 'release_group_dist_d1', routineP = moduleN//':'//routineN

      DEALLOCATE(this%starts)
      DEALLOCATE(this%ends)
      DEALLOCATE(this%sizes)
      
   END SUBROUTINE release_group_dist_d1
END MODULE group_dist_types