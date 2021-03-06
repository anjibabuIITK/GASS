
!--------------------------------------------------------------------!
!      This code is a part of GASS Reweighting codes                 !
! Fortran program to calculate the 4D probability distribution after !
! reweighting the metadynamics bias potentail in GASS sumulation     !
!--------------------------------------------------------------------!
!
PROGRAM prob_factor
IMPLICIT NONE
REAL*8 :: gridmin1, gridmax1, griddiff1, gridmin2, gridmax2, griddiff2
REAL*8 :: gridmin3, gridmax3, griddiff3, gridmin4, gridmax4, griddiff4
REAL*8 :: T0, T, ktb, bias_fact, alpha_cv, deltaT, den,kbT, kbT0
REAL*8 :: diff_s2, ds2, ss, hh, dum, num, alpha
REAL*8, ALLOCATABLE :: prob(:,:,:,:)
REAL*8, ALLOCATABLE :: cv1(:), cv2(:), vbias(:)
REAL*8, ALLOCATABLE :: cv3(:), cv4(:), ct(:)
INTEGER :: mtd_steps, md_steps, i, t_min, t_max, s1
INTEGER :: mtd_max, w_cv, w_hill, i_mtd, i_md, s2, s3, s4
INTEGER :: i_s1, i_s2, i_s3, i_s4, nbin1, nbin2, nbin3, nbin4
INTEGER :: index1, index2, index3, index4

REAL*8, PARAMETER :: kb=1.9872041E-3 !kcal K-1 mol-1
REAL*8, PARAMETER :: kj_to_kcal = 0.239006

OPEN(1,FILE='input',STATUS='old')
!OPEN(2,FILE='PROB_4D.dat',STATUS='replace',form='unformatted')
OPEN(2,FILE='PROB_4D',STATUS='replace')
OPEN(11,FILE='COLVAR',STATUS='old')
OPEN(12,FILE='HILLS',STATUS='old')
OPEN(21,file='data_ct.dat',status='old')
OPEN(22,file='data_vbias.dat',status='old')


CALL get_steps(11,md_steps)
CALL get_steps(12,mtd_steps)

!print *, 'md_steps=', md_steps, 'mtd_steps=', mtd_steps

read(1,*) T, T, bias_fact
read(1,*) t_min, t_max

IF(t_max.gt.md_steps)STOP '!!ERROR: t_max > total MD steps'

read(1,*) gridmin1, gridmax1, griddiff1
read(1,*) gridmin2, gridmax2, griddiff2
read(1,*) gridmin3, gridmax3, griddiff3
read(1,*) gridmin4, gridmax4, griddiff4
read(1,*) w_cv, w_hill


 deltaT = (bias_fact - 1.d0)*T
 alpha  = (T + deltaT)/deltaT

 kbT = kb*T
 ktb = kbT*bias_fact


WRITE(*,'(A,I10)')'No: of MTD steps        =',mtd_steps
WRITE(*,'(A,I10)')'No: of MD  steps        =',md_steps
WRITE(*,'(A,F9.2)')'Physical Temp (K)      =',T
WRITE(*,'(A,F9.2)')'CV Temp (K)            =',T
WRITE(*,'(A,F9.2)')'Bias Factor (K)        =',bias_fact
WRITE(*,'(A,I10)')'Print Freq. cvmdck_mtd  =',w_cv
WRITE(*,'(A,I10)')'Freq. of Hill Update    =',w_hill
WRITE(*,'(A,I10)')'Reweigtht: Min step     =',t_min
WRITE(*,'(A,I10)')'Reweigtht: Max step     =',t_max
WRITE(*,'(A,F9.2)')'DeltaT      (K)        =',deltaT
WRITE(*,'(A,F9.2)')'Alpha value            =',alpha


ALLOCATE(cv1(md_steps),cv2(md_steps))
ALLOCATE(cv3(md_steps),cv4(md_steps))
ALLOCATE(vbias(md_steps),ct(mtd_steps))


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

write(*,*) "reading vbias.dat file"

do i_md=1,md_steps
  read(22,*) dum, vbias(i_md)
end do

write(*,*) "reading ct.dat file"
do i_mtd=1,mtd_steps
  read(21,*) dum, ct(i_mtd)
end do

ALLOCATE(prob(nbin1,nbin2,nbin3,nbin4))


WRITE(*,*) 'calculating  probability'

den=0.d0
prob=0.d0

DO i_md=1,md_steps
 IF((i_md.GT.t_min).AND.(i_md.LT.t_max))THEN
 index1 = nint((cv1(i_md)-gridmin1)/griddiff1) +1
 index2 = nint((cv2(i_md)-gridmin2)/griddiff2) +1
 index3 = nint((cv3(i_md)-gridmin3)/griddiff3) +1
 index4 = nint((cv4(i_md)-gridmin4)/griddiff4) +1

     IF(index1.gt.0.and.index2.gt.0.and.index3.gt.0.and.index4.gt.0.and.index1.le.&
        nbin1.and.index2.le.nbin2.and.index3.le.nbin3.and.index4.le.nbin4) then

      i_mtd=(i_md*w_cv/w_hill)

      IF(i_mtd == 0) THEN
        dum=0.d0
      ELSE
        dum=vbias(i_md) - ct(i_mtd)
      ENDIF

      prob(index1,index2,index3,index4) = prob(index1,index2,index3,index4) + DEXP(dum/kbT)
      den=den+DEXP(dum/kbT)
     END IF

 END IF
END DO

  dum=den*griddiff1*griddiff2*griddiff3*griddiff4
  den=1.d0/dum


DO i_s1=1,nbin1
s1=DFLOAT(i_s1-1)*griddiff1+gridmin1
   DO i_s2=1,nbin2
   s2=DFLOAT(i_s2-1)*griddiff2+gridmin2
      DO i_s3=1,nbin3
      s3=DFLOAT(i_s3-1)*griddiff3+gridmin3
         DO i_s4=1,nbin4
         s4=DFLOAT(i_s4-1)*griddiff4+gridmin4

           prob(i_s1,i_s2,i_s3,i_s4)=prob(i_s1,i_s2,i_s3,i_s4)*den
          
           WRITE(2,'(E16.8)')prob(i_s1,i_s2,i_s3,i_s4)
         END DO
      END DO
   END DO
END DO
 WRITE(*,'(A)')'Unbiased distribution written in PROB_4D.dat'

close(1)
close(2)
close(11)
close(12)
close(21)
close(22)

DEALLOCATE(cv1, cv2, vbias, ct)
DEALLOCATE(cv3, cv4)
DEALLOCATE(prob)

END PROGRAM

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
!------------------------------------------------------------------------------------!
!
