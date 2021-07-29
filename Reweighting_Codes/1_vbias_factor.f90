
!------------------------------------------------------------------!
!      This code is a part of GASS Reweighting codes               !
! Fortran program to calculate the bias potentail applied along    !
!          the metadynamics CV in GASS sumulation                  !
!------------------------------------------------------------------!
!
!
PROGRAM vb_factor
IMPLICIT NONE
REAL*8 :: gridmin1, gridmax1, griddiff1, gridmin2, gridmax2, griddiff2
REAL*8 :: gridmin3, gridmax3, griddiff3, gridmin4, gridmax4, griddiff4
REAL*8 :: T0, T, ktb, bias_fact, alpha_cv, deltaT, den,kbT, kbT0
REAL*8 :: diff_s2, ds2, ss, hh, dum, num, gamma_,alpha
REAL*8, ALLOCATABLE :: cv1(:), cv2(:), ht(:), vbias(:), hill(:)
REAL*8, ALLOCATABLE :: cv3(:), cv4(:), width(:)
INTEGER :: mtd_steps, md_steps, i, t_min, t_max 
INTEGER :: mtd_max, w_cv, w_hill, i_mtd, i_md, nbin1
INTEGER :: i_s1, i_s2, i_s3, i_s4, nbin2, nbin3, nbin4

REAL*8, PARAMETER :: kb=1.9872041E-3 !kcal K-1 mol-1
REAL*8, PARAMETER :: kj_to_kcal = 0.239006

open(1,FILE='input',STATUS='old')
OPEN(11,FILE='COLVAR',STATUS='old')
OPEN(12,FILE='HILLS',STATUS='old')
OPEN(21,FILE='data_vbias.dat',STATUS='replace')


CALL get_steps(11,md_steps)
CALL get_steps(12,mtd_steps)

!print *, 'md_steps=', md_steps, 'mtd_steps=', mtd_steps

read(1,*) T,bias_fact
read(1,*) t_min, t_max

IF(t_max.gt.md_steps)STOP '!!ERROR: t_max > total MD steps'

read(1,*) gridmin1, gridmax1, griddiff1
read(1,*) gridmin2, gridmax2, griddiff2
read(1,*) gridmin3, gridmax3, griddiff3
read(1,*) gridmin4, gridmax4, griddiff4
read(1,*) w_cv, w_hill

 deltaT = (bias_fact - 1.d0)*T
 alpha = (T + deltaT)/deltaT

 kbT = kb*T

!write(*,*), 'gamma_=', gamma_

WRITE(*,'(A,I10)')'No: of MTD steps        =',mtd_steps
WRITE(*,'(A,I10)')'No: of MD  steps        =',md_steps
WRITE(*,'(A,F9.2)')'Physical Temp (K)      =',T
WRITE(*,'(A,F9.2)')'CV Temp (K)            =',T
WRITE(*,'(A,F9.2)')'Bias Factor (K)        =',bias_fact
WRITE(*,'(A,F9.2)')'DeltaT      (K)        =',deltaT
WRITE(*,'(A,F9.2)')'Alpha value            =',alpha
WRITE(*,'(A,I10)')'Print Freq. cvmdck_mtd  =',w_cv
WRITE(*,'(A,I10)')'Freq. of Hill Update    =',w_hill
WRITE(*,'(A,I10)')'Reweigtht: Min step     =',t_min
WRITE(*,'(A,I10)')'Reweigtht: Max step     =',t_max


ALLOCATE(cv1(md_steps),cv2(md_steps))
ALLOCATE(cv3(md_steps),cv4(md_steps))
ALLOCATE(vbias(md_steps))
ALLOCATE(ht(mtd_steps))
ALLOCATE(hill(mtd_steps),width(mtd_steps))


DO i_md=1,md_steps
 READ(11,*) dum,cv1(i_md),cv2(i_md),cv3(i_md),cv4(i_md)
     IF( cv1(i_md) .gt.  3.14d0)  cv1(i_md) = cv1(i_md) - 6.28d0
     IF( cv1(i_md) .lt. -3.14d0 ) cv1(i_md) = cv1(i_md) + 6.28d0
     IF( cv2(i_md) .gt.  3.14d0)  cv2(i_md) = cv2(i_md) - 6.28d0
     IF( cv2(i_md) .lt. -3.14d0 ) cv2(i_md) = cv2(i_md) + 6.28d0
     IF( cv3(i_md) .gt.  3.14d0)  cv3(i_md) = cv3(i_md) - 6.28d0
     IF( cv3(i_md) .lt. -3.14d0 ) cv3(i_md) = cv3(i_md) + 6.28d0
     IF( cv4(i_md) .gt.  3.14d0)  cv4(i_md) = cv4(i_md) - 6.28d0
     IF( cv4(i_md) .lt. -3.14d0 ) cv4(i_md) = cv4(i_md) + 6.28d0
END DO

nbin1 = NINT((gridmax1-gridmin1)/griddiff1)+1
nbin2 = NINT((gridmax2-gridmin2)/griddiff2)+1
nbin3 = NINT((gridmax3-gridmin3)/griddiff3)+1
nbin4 = NINT((gridmax4-gridmin4)/griddiff4)+1

write(*,*) nbin1, nbin2, nbin3, nbin4

DO i_mtd=1,mtd_steps
 READ(12,*) dum,hill(i_mtd),width(i_mtd),ht(i_mtd)
      IF( hill(i_mtd) .gt.  3.14d0) hill(i_mtd) = hill(i_mtd) - 6.28d0
      IF( hill(i_mtd) .lt. -3.14d0 )hill(i_mtd) = hill(i_mtd) + 6.28d0
       ht(i_mtd)=ht(i_mtd)*kj_to_kcal
END DO

 write(*,*) 'calculating vbias'

DO i_md=1,md_steps
  mtd_max=(i_md*w_cv/w_hill)
ss=cv2(i_md)
 dum=0.d0
   DO i_mtd=1,mtd_max
    ds2=width(i_mtd)*width(i_mtd)
    hh=ht(i_mtd)/alpha
    diff_s2=ss-hill(i_mtd)
     if (diff_s2 .gt. 3.14d0 ) diff_s2 =diff_s2 - 6.28d0
     if (diff_s2 .lt.-3.14d0 ) diff_s2 =diff_s2 + 6.28d0
    diff_s2=diff_s2*diff_s2*0.5D0
    dum=dum+hh*DEXP(-diff_s2/ds2)
   END DO
vbias(i_md)=dum
write(21,*) i_md, vbias(i_md)
END DO

write(*,*) " vbias written in data_vbias.dat file. "

close(1)
close(11)
close(21)
close(12)

DEALLOCATE(cv2, ht, vbias, hill)
DEALLOCATE(cv3, cv4, width, cv1)

END PROGRAM vb_factor

SUBROUTINE get_steps(iunit,nsteps)
 IMPLICIT NONE
 INTEGER :: iunit, nsteps
 INTEGER :: ios
  nsteps=0
   REWIND(iunit)
     Read_Loop: DO
       READ(iunit,*,IOSTAT=ios)
       IF(ios.ne.0)EXIT Read_Loop
       nsteps=nsteps+1
       END DO Read_Loop
   REWIND(iunit)
END SUBROUTINE
!------------------------------------------------------------------!
!   This code is a part of GASS Reweighting codes                  !
!------------------------------------------------------------------!
