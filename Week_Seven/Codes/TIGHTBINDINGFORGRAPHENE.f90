SUBROUTINE DOTPRODUCT(vector1,vector2,volume)

IMPLICIT NONE

INTEGER, PARAMETER             :: dp = SELECTED_REAL_KIND(15,14)    !Accuracy for the floating variable
REAL (KIND=dp)                 :: vector1(3), vector2(3), volume    !Variables between main and subroutine codes

volume = DOT_PRODUCT(vector1,vector2)

RETURN
END SUBROUTINE DOTPRODUCT

SUBROUTINE CROSSPRODUCT(vector1,vector2,result)

IMPLICIT NONE

INTEGER, PARAMETER             :: dp = SELECTED_REAL_KIND(15,14)    !Accuracy for the floating variable
REAL (KIND=dp)                 :: vector1(3), vector2(3), result(3) !Variables between main and subroutine codes

result(1) = vector1(2)*vector2(3)-vector1(3)*vector2(2)
result(2) = vector1(3)*vector2(1)-vector1(1)*vector2(3)
result(3) = vector1(1)*vector2(2)-vector1(2)*vector2(1)

RETURN
END SUBROUTINE CROSSPRODUCT

SUBROUTINE KSPACE(latticeinrealspace,latticeinkspace)

IMPLICIT NONE

INTEGER, PARAMETER             :: dp = SELECTED_REAL_KIND(15,14) !Accuracy for the floating variable
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: latticeinkspace(3,3)     !Lattice constant for unit cell in the reciprocal space
REAL (KIND=dp)                 :: volume                   !Volume or area or length of the unit cell in the real space
REAL (KIND=dp)                 :: cross(3)                 !Cross product of two vectors
REAL (KIND=dp)                 :: pi                       !Constant pi

pi = DACOS(-1.0d0)

CALL CROSSPRODUCT(latticeinrealspace(:,2),latticeinrealspace(:,3),cross)
CALL DOTPRODUCT(latticeinrealspace(:,1),cross,volume)
latticeinkspace(:,1) = cross / volume
CALL CROSSPRODUCT(latticeinrealspace(:,3),latticeinrealspace(:,1),cross)
latticeinkspace(:,2) = cross / volume
CALL CROSSPRODUCT(latticeinrealspace(:,1),latticeinrealspace(:,2),cross)
latticeinkspace(:,3) = cross / volume

latticeinkspace = latticeinkspace * 2.0d0 * pi

RETURN
END SUBROUTINE KSPACE

MODULE GEOMETRY

IMPLICIT NONE

INTEGER, PARAMETER             :: dp = SELECTED_REAL_KIND(15,14) !Accuracy for the floating variable

TYPE :: neighbour
     INTEGER                   :: atomi                    !Coordinate of Atom i
     INTEGER                   :: atomj                    !Coordinate of Atom j
     REAL (KIND=dp)            :: rvector(3)               !Vector pointing from atom i to atom j
     REAL (KIND=dp)            :: region                   !Distance between each atom pair
END TYPE neighbour

CONTAINS
SUBROUTINE NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nbond,bondlist,distance,delta)

INTEGER                        :: i, j
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: atomcoordinate(3,2)      !Coodinate of atom in the unit cell
INTEGER                        :: natom                    !Total number of atom in the unit cell
TYPE (neighbour), ALLOCATABLE  :: bondlist(:)              !Variable to store the first neighbour bonding pair
INTEGER                        :: nbond                    !Number of the first neighbour bonding pair
REAL (KIND=dp)                 :: distance                 !Distance for the first neighbour atom pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
INTEGER                        :: n1, n2, n3               !Variables to compose the R vector in the real space
INTEGER                        :: bondindex                !Number counter of the first neighbour atom pair
REAL (KIND=dp)                 :: rcell(3)                 !Variable to store the R vector in the real space
REAL (KIND=dp)                 :: atomdistance             !Distance between each atom pair

IF (ALLOCATED(bondlist)) DEALLOCATE (bondlist)
ALLOCATE (bondlist(natom**2*9))

nbond = 0
bondindex = 0

DO i = 1, natom, 1
   DO j = 1, natom, 1
      DO n1 = -1, 1, 1
         DO n2 = -1, 1, 1
            DO n3 = -1, 1, 1
               rcell = n1*latticeinrealspace(:,1)+n2*latticeinrealspace(:,2)+n3*latticeinrealspace(:,3)
               atomdistance = DSQRT(SUM((atomcoordinate(:,i)-atomcoordinate(:,j)+rcell)**2))
               IF ((atomdistance >= distance-delta) .AND. (atomdistance <= distance+delta)) THEN
                  bondindex = bondindex+1
                  bondlist(bondindex)%atomi = i
                  bondlist(bondindex)%atomj = j
                  bondlist(bondindex)%region = atomdistance
                  bondlist(bondindex)%rvector = atomcoordinate(:,i)-atomcoordinate(:,j)+rcell
               END IF
            END DO
         END DO
      END DO
   END DO
END DO

nbond = bondindex

BLOCK
   TYPE (neighbour), ALLOCATABLE :: templist(:)
   ALLOCATE (templist(nbond))
   templist = bondlist(1:nbond)
   CALL MOVE_ALLOC(FROM=templist, TO=bondlist)
END BLOCK

RETURN
END SUBROUTINE NEIGHBOURHAMILTONIAN

SUBROUTINE SURFACEGREENFUNCTION(energyvalue,electrodesize,electrodeh00,electrodeh01,surfacegreen,eta)

INTEGER                        :: i
REAL (KIND=dp)                 :: energyvalue              !Energy value for the surface green function
INTEGER                        :: electrodesize(2)         !Supercell size for the electrode (same for left and right)
COMPLEX (KIND=dp), INTENT(IN)  :: electrodeh00(:,:)        !H00 for the electrode
COMPLEX (KIND=dp), INTENT(IN)  :: electrodeh01(:,:)        !H01 for the electrode
COMPLEX (KIND=dp), INTENT(OUT) :: surfacegreen(:,:)        !Surface green function for the electrode
REAL (KIND=dp)                 :: eta                      !Broadening value in the green function
INTEGER                        :: cyclingtimes             !Maximum cycling times for the iteration
REAL (KIND=dp)                 :: convergence              !convergence criterion
LOGICAL                        :: converged                !Whether the self-energy iteration converged
COMPLEX (KIND=dp), ALLOCATABLE :: sigmamatrix(:,:)         !Self-energy of the semi-infinite electrode
COMPLEX (KIND=dp), ALLOCATABLE :: newsigma(:,:)            !Updated self-energy
COMPLEX (KIND=dp), ALLOCATABLE :: internalmatrix1(:,:)     !Internal matrix
COMPLEX (KIND=dp), ALLOCATABLE :: internalmatrix2(:,:)     !Internal matrix

INTEGER                        :: lwork                    !Variable for inverse matrix calculation
INTEGER                        :: info                     !Variable for inverse matrix calculation
INTEGER, ALLOCATABLE           :: ipiv(:)                  !Variable for inverse matrix calculation
COMPLEX (KIND=dp), ALLOCATABLE :: work(:)                  !Variable for inverse matrix calculation

cyclingtimes = 2000
convergence = 1.0d-10
ALLOCATE (sigmamatrix(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (newsigma(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (internalmatrix1(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (internalmatrix2(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
lwork = (electrodesize(1)*electrodesize(2)*2)**2
ALLOCATE (ipiv(electrodesize(1)*electrodesize(2)*2))
ALLOCATE (work(lwork))

surfacegreen = CMPLX(0.0d0, 0.0d0, KIND=dp)
converged = .FALSE.
sigmamatrix = CMPLX(0.0d0, 0.0d0, KIND=dp)
newsigma = CMPLX(0.0d0, 0.0d0, KIND=dp)
internalmatrix2 = CMPLX (0.0, 0.0, KIND=dp)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   internalmatrix2(i,i) = CMPLX(1.0, 0.0, KIND=dp)*energyvalue+CMPLX(0.0, 1.0, KIND=dp)*eta
END DO
DO i = 1, cyclingtimes, 1
   internalmatrix1 = internalmatrix2-electrodeh00-sigmamatrix
   CALL ZGETRF(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2,&
               internalmatrix1,electrodesize(1)*electrodesize(2)*2,ipiv,info)
    IF (info /= 0) THEN
       WRITE (UNIT=8, FMT='(A16,I3,A25,I2)') 'ZGETRF failed at', i, 'th iteration with info =', info
       surfacegreen = CMPLX(0.0d0, 0.0d0, KIND=dp)
       RETURN
   END IF
   CALL ZGETRI(electrodesize(1)*electrodesize(2)*2,internalmatrix1,&
               electrodesize(1)*electrodesize(2)*2,ipiv,work,lwork,info)
    IF (info /= 0) THEN
       WRITE (UNIT=8, FMT='(A16,I3,A25,I2)') 'ZGETRI failed at', i, 'th iteration with info =', info
       surfacegreen = CMPLX(0.0d0, 0.0d0, KIND=dp)
       RETURN
   END IF
   newsigma = MATMUL(MATMUL(electrodeh01,internalmatrix1),CONJG(TRANSPOSE(electrodeh01)))
   IF (i > 500 .AND. MOD(i,50) == 0) THEN
      WRITE(UNIT=8, FMT=*) 'Iter ', i, ' maxdiff = ', MAXVAL(ABS(newsigma-sigmamatrix))
   END IF
   IF (MAXVAL(ABS(newsigma-sigmamatrix)) < convergence) THEN
      sigmamatrix = newsigma
      converged = .TRUE.
      EXIT
   END IF
   sigmamatrix = newsigma
END DO
IF (.NOT. converged) THEN
   WRITE(UNIT=8, FMT='(A)') 'WARNING: Surface Green Function did not converge!'
END IF
surfacegreen = internalmatrix2-electrodeh00-sigmamatrix
CALL ZGETRF(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2,&
            surfacegreen,electrodesize(1)*electrodesize(2)*2,ipiv,info)
IF (info /= 0) THEN
   WRITE (UNIT=8, FMT='(A26,I2)') 'ZGETRF failed with info =', info
   surfacegreen = CMPLX(0.0d0, 0.0d0, KIND=dp)
   RETURN
END IF
CALL ZGETRI(electrodesize(1)*electrodesize(2)*2,surfacegreen,&
            electrodesize(1)*electrodesize(2)*2,ipiv,work,lwork,info)
IF (info /= 0) THEN
   WRITE (UNIT=8, FMT='(A26,I2)') 'ZGETRI failed with info =', info
   surfacegreen = CMPLX(0.0d0, 0.0d0, KIND=dp)
   RETURN
END IF

DEALLOCATE (sigmamatrix)
DEALLOCATE (newsigma)
DEALLOCATE (internalmatrix1)
DEALLOCATE (internalmatrix2)
DEALLOCATE (ipiv)
DEALLOCATE (work)

RETURN
END SUBROUTINE SURFACEGREENFUNCTION

END MODULE GEOMETRY

MODULE PROPERTY

USE GEOMETRY

CONTAINS

SUBROUTINE TRANSMISSION(kcoordinate,energyvalue,nfirstbond,firstlist,onsite,hopping,electrodesize,scatteringsize,electrodervector,&
                        scatteringcoor,electrodecoor,latticeinrealspace,firstneighbour,delta,eta,transcoefficient)

IMPLICIT NONE

INTEGER                        :: i, j, k
REAL (KIND=dp)                 :: kcoordinate(3)           !Coordinate of k point
REAL (KIND=dp)                 :: energyvalue              !Energy value for the green function
INTEGER                        :: nfirstbond               !Number of the first neighbour bonding pair
TYPE (neighbour), ALLOCATABLE  :: firstlist(:)             !Variable to store the first neighbour bonding pair
REAL (KIND=dp), ALLOCATABLE    :: onsite(:)                !Variable to store the onsite energy
REAL (KIND=dp)                 :: hopping                  !Hopping value with Unit of eV
INTEGER                        :: electrodesize(2)         !Supercell size for the electrode (same for left and right)
INTEGER                        :: scatteringsize(2)        !Supercell size for the centre scattering region
REAL (KIND=dp)                 :: electrodervector(3)      !R vector for the electrode in the real space
REAL (KIND=dp), ALLOCATABLE    :: electrodecoor(:,:)       !Coordinate of atoms in the electrode
REAL (KIND=dp), ALLOCATABLE    :: scatteringcoor(:,:)      !Coordinate of atoms in the scattering centre
REAL (KIND=dp), ALLOCATABLE    :: leftelectrodecoor(:,:)   !Coordinate of atoms in the left electrode
REAL (KIND=dp), ALLOCATABLE    :: rightelectrodecoor(:,:)  !Coordinate of atoms in the right electrode
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: firstneighbour           !Distance for the first neighbour atom pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
COMPLEX (KIND=dp), ALLOCATABLE :: electrodeh00(:,:)        !H00 for the electrode
COMPLEX (KIND=dp), ALLOCATABLE :: electrodeh01(:,:)        !H01 for the electrode
COMPLEX (KIND=dp), ALLOCATABLE :: electrodeh01left(:,:)    !H01 dagger for the left electrode
COMPLEX (KIND=dp), ALLOCATABLE :: leftsurfacegreen(:,:)    !Surface green function for the left electrode
COMPLEX (KIND=dp), ALLOCATABLE :: rightsurfacegreen(:,:)   !Surface green function for the right electrode
REAL (KIND=dp)                 :: eta                      !Broadening value in the green function
REAL (KIND=dp)                 :: shiftvector(3)           !Shift vector
REAL (KIND=dp)                 :: transversevector(3)      !Periodic vector along the transverse direction
REAL (KIND=dp)                 :: distance                 !Distance between atoms
REAL (KIND=dp)                 :: vectoratom(3)            !Vector between atoms in the electrode
COMPLEX (KIND=dp), ALLOCATABLE :: leftscattering(:,:)      !Coupling matrix between left electrode and scattering region
COMPLEX (KIND=dp), ALLOCATABLE :: rightscattering(:,:)     !Coupling matrix between scattering region and right electrode
COMPLEX (KIND=dp), ALLOCATABLE :: leftself(:,:)            !Self energy matrix the left electrode
COMPLEX (KIND=dp), ALLOCATABLE :: rightself(:,:)           !Self energy matrix the right electrode
COMPLEX (KIND=dp), ALLOCATABLE :: leftbroadening(:,:)      !Broadening function for the left electrode
COMPLEX (KIND=dp), ALLOCATABLE :: rightbroadening(:,:)     !Broadening function for the right electrode
COMPLEX (KIND=dp), ALLOCATABLE :: retardgreencentre(:,:)   !Retarded green function for the scattering region
COMPLEX (KIND=dp), ALLOCATABLE :: advancegreencentre(:,:)  !Advanced green function for the scattering region
COMPLEX (KIND=dp), ALLOCATABLE :: scatteringregion(:,:)    !Hamiltonian matrix for the scattering region
COMPLEX (KIND=dp), ALLOCATABLE :: transmatrix(:,:)         !Transmission matrix
COMPLEX (KIND=dp)              :: transcoefficient         !Sum of diagonal term of transmission matrix
COMPLEX (KIND=dp), ALLOCATABLE :: internalmatrix(:,:)      !Internal matrix

INTEGER                        :: lwork                    !Variable for inverse matrix calculation
INTEGER                        :: info                     !Variable for inverse matrix calculation
INTEGER, ALLOCATABLE           :: ipiv(:)                  !Variable for inverse matrix calculation
COMPLEX (KIND=dp), ALLOCATABLE :: work(:)                  !Variable for inverse matrix calculation

transcoefficient = CMPLX(0.0d0, 0.0d0, KIND=dp)

!Re-organising coordinates for left and right electrodes
ALLOCATE (leftelectrodecoor(3,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (rightelectrodecoor(3,electrodesize(1)*electrodesize(2)*2))
shiftvector = electrodesize(1)*latticeinrealspace(:,1)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   leftelectrodecoor(:,i) = electrodecoor(:,i)-shiftvector
END DO
shiftvector = scatteringsize(1)*latticeinrealspace(:,1)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   rightelectrodecoor(:,i) = electrodecoor(:,i)+shiftvector
END DO

!Parameterizing H00 and H01 for the electrode
ALLOCATE (electrodeh00(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (electrodeh01(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (electrodeh01left(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (leftsurfacegreen(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (rightsurfacegreen(electrodesize(1)*electrodesize(2)*2,electrodesize(1)*electrodesize(2)*2))
electrodeh00 = CMPLX(0.0d0, 0.0d0, KIND=dp)
electrodeh01 = CMPLX(0.0d0, 0.0d0, KIND=dp)
transversevector = electrodesize(2)*latticeinrealspace(:,2)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   electrodeh00(i,i) = CMPLX(onsite(MOD(i-1,2)+1), 0.0, KIND=dp)
END DO
shiftvector = electrodesize(1)*latticeinrealspace(:,1)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   DO j = 1, electrodesize(1)*electrodesize(2)*2, 1
      DO k = -1, 1, 1
         vectoratom = leftelectrodecoor(:,j)+DBLE(k)*transversevector-leftelectrodecoor(:,i)
         distance = DSQRT(SUM(vectoratom**2))
         IF (ABS(distance-firstneighbour) < delta) THEN
            electrodeh00(i,j) = electrodeh00(i,j)+hopping*EXP(CMPLX(0.0,1.0,KIND=dp)*DOT_PRODUCT(kcoordinate,vectoratom))
         END IF

         vectoratom = vectoratom+shiftvector
         distance = DSQRT(SUM(vectoratom**2))
         IF (ABS(distance-firstneighbour) < delta) THEN
            electrodeh01(i,j) = electrodeh01(i,j)+hopping*EXP(CMPLX(0.0,1.0,KIND=dp)*DOT_PRODUCT(kcoordinate,vectoratom))
         END IF
      END DO
   END DO
END DO
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   DO j = i+1, electrodesize(1)*electrodesize(2)*2, 1
      electrodeh00(j,i) = CONJG(electrodeh00(i,j))
   END DO
END DO
electrodeh01left = CONJG(TRANSPOSE(electrodeh01))
CALL SURFACEGREENFUNCTION(energyvalue,electrodesize,electrodeh00,electrodeh01left,leftsurfacegreen,eta)
CALL SURFACEGREENFUNCTION(energyvalue,electrodesize,electrodeh00,electrodeh01,rightsurfacegreen,eta)
!
!Calculating the coupling matrix between electrodes and scattering region
ALLOCATE (leftscattering(electrodesize(1)*electrodesize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (rightscattering(scatteringsize(1)*scatteringsize(2)*2,electrodesize(1)*electrodesize(2)*2))
leftscattering = CMPLX(0.0d0, 0.0d0, KIND=dp)
rightscattering = CMPLX(0.0d0, 0.0d0, KIND=dp)
transversevector = scatteringsize(2)*latticeinrealspace(:,2)
DO i = 1, electrodesize(1)*electrodesize(2)*2, 1
   DO j = 1, scatteringsize(1)*scatteringsize(2)*2, 1
      DO k = -1, 1, 1
         vectoratom = scatteringcoor(:,j)+DBLE(k)*transversevector-leftelectrodecoor(:,i)
         distance = DSQRT(SUM(vectoratom**2))
         IF (ABS(distance-firstneighbour) < delta) THEN
            leftscattering(i,j) = leftscattering(i,j)+hopping*EXP(CMPLX(0.0,1.0,KIND=dp)*DOT_PRODUCT(kcoordinate,vectoratom))
         END IF
      END DO
   END DO
END DO
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   DO j = 1, electrodesize(1)*electrodesize(2)*2, 1
      DO k = -1, 1, 1
         vectoratom = rightelectrodecoor(:,j)+DBLE(k)*transversevector-scatteringcoor(:,i)
         distance = DSQRT(SUM(vectoratom**2))
         IF (ABS(distance-firstneighbour) < delta) THEN
            rightscattering(i,j) = rightscattering(i,j)+hopping*EXP(CMPLX(0.0,1.0,KIND=dp)*DOT_PRODUCT(kcoordinate,vectoratom))
         END IF
      END DO
   END DO
END DO
!
!Calculating the self energy for electrodes
ALLOCATE (leftself(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (rightself(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
leftself = MATMUL(MATMUL(CONJG(TRANSPOSE(leftscattering)),leftsurfacegreen),leftscattering)
rightself = MATMUL(MATMUL(rightscattering,rightsurfacegreen),CONJG(TRANSPOSE(rightscattering)))
!
!Calculating the broadening function for electrodes
ALLOCATE (leftbroadening(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (rightbroadening(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
leftbroadening = CMPLX(0.0, 1.0, KIND=dp)*(leftself-CONJG(TRANSPOSE(leftself)))
rightbroadening = CMPLX(0.0, 1.0, KIND=dp)*(rightself-CONJG(TRANSPOSE(rightself)))
!Calculating the Hamiltonian matrix for the scattering region
ALLOCATE (scatteringregion(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
scatteringregion = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   scatteringregion(i,i) = CMPLX(onsite(MOD(i-1,2)+1), 0.0, KIND=dp)
END DO
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   DO j = 1, scatteringsize(1)*scatteringsize(2)*2, 1
      DO k = -1, 1, 1
         vectoratom = scatteringcoor(:,j)+DBLE(k)*transversevector-scatteringcoor(:,i)
         distance = DSQRT(SUM(vectoratom**2))
         IF (ABS(distance-firstneighbour) < delta) THEN
            scatteringregion(i,j) = scatteringregion(i,j)+hopping*EXP(CMPLX(0.0,1.0,KIND=dp)*DOT_PRODUCT(kcoordinate,vectoratom))
         END IF
      END DO
   END DO
END DO
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   DO j = i+1, scatteringsize(1)*scatteringsize(2)*2, 1
      scatteringregion(j,i) = CONJG(scatteringregion(i,j))
   END DO
END DO
!Calculating the retaded and advanced green functions for the scattering region
ALLOCATE (retardgreencentre(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (advancegreencentre(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (internalmatrix(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
lwork = (scatteringsize(1)*scatteringsize(2)*2)**2
ALLOCATE (ipiv(scatteringsize(1)*scatteringsize(2)*2))
ALLOCATE (work(lwork))
internalmatrix = CMPLX (0.0, 0.0, KIND=dp)
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   internalmatrix(i,i) = CMPLX(1.0, 0.0, KIND=dp)*energyvalue+CMPLX(0.0, 1.0, KIND=dp)*eta
END DO
retardgreencentre = internalmatrix-scatteringregion-leftself-rightself
CALL ZGETRF(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2,&
            retardgreencentre,scatteringsize(1)*scatteringsize(2)*2,ipiv,info)
IF (info /= 0) THEN
   WRITE (UNIT=8, FMT='(A25,I2)') 'ZGETRF failed with info =', info
   RETURN
END IF
CALL ZGETRI(scatteringsize(1)*scatteringsize(2)*2,retardgreencentre,&
            scatteringsize(1)*scatteringsize(2)*2,ipiv,work,lwork,info)
IF (info /= 0) THEN
   WRITE (UNIT=8, FMT='(A25,I2)') 'ZGETRI failed with info =', info
   RETURN
END IF
advancegreencentre = CONJG(TRANSPOSE(retardgreencentre))
!Calculating the trace of the transmission matrix
ALLOCATE (transmatrix(scatteringsize(1)*scatteringsize(2)*2,scatteringsize(1)*scatteringsize(2)*2))
internalmatrix = MATMUL(leftbroadening,retardgreencentre)
internalmatrix = MATMUL(internalmatrix,rightbroadening)
transmatrix = MATMUL(internalmatrix,advancegreencentre)
transcoefficient = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, scatteringsize(1)*scatteringsize(2)*2, 1
   transcoefficient = transcoefficient + transmatrix(i,i)
END DO
!

DEALLOCATE (leftelectrodecoor)
DEALLOCATE (rightelectrodecoor)
DEALLOCATE (electrodeh00)
DEALLOCATE (electrodeh01)
DEALLOCATE (electrodeh01left)
DEALLOCATE (leftsurfacegreen)
DEALLOCATE (rightsurfacegreen)
DEALLOCATE (leftscattering)
DEALLOCATE (rightscattering)
DEALLOCATE (leftself)
DEALLOCATE (rightself)
DEALLOCATE (leftbroadening)
DEALLOCATE (rightbroadening)
DEALLOCATE (retardgreencentre)
DEALLOCATE (advancegreencentre)
DEALLOCATE (scatteringregion)
DEALLOCATE (transmatrix)
DEALLOCATE (internalmatrix)
DEALLOCATE (ipiv)
DEALLOCATE (work)

RETURN
END SUBROUTINE TRANSMISSION

END MODULE PROPERTY

PROGRAM TIGHTBINDINGFORGRAPHENE

USE GEOMETRY

USE PROPERTY

IMPLICIT NONE

INTEGER                        :: i, j, k, l
CHARACTER (LEN=100)            :: str                      !Variable to store data from 'Graphene.vasp' file
REAL (KIND=dp)                 :: inter(5)                 !Variable for chemical potential in Fermi-Dirac Distribution
REAL (KIND=dp)                 :: scalingfactor            !Scaling factor in 'Graphene.vasp' file
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: latticeinkspace(3,3)     !Lattice constant for unit cell in the reciprocal space
INTEGER                        :: natom                    !Total number of atom in the unit cell
REAL (KIND=dp), ALLOCATABLE    :: onsite(:)                !Variable to store the onsite energy
REAL (KIND=dp)                 :: hopping                  !Hopping value with Unit of eV
REAL (KIND=dp)                 :: energyrange(2)           !Energy range for NEGF method
INTEGER                        :: numenergypoint           !Number of energy point
REAL (KIND=dp), ALLOCATABLE    :: energypoint(:)           !Energy point for NEGF method
INTEGER                        :: kmesh(2)                 !k point mesh for NEGF method
REAL (KIND=dp)                 :: voltagerange(2)          !Voltage range for NEGF method
REAL (KIND=dp), ALLOCATABLE    :: kpoint(:,:)              !Coordinate k point for NEGF method
INTEGER                        :: numvoltagepoint          !Number of voltage point for NEGF method
REAL (KIND=dp)                 :: broadening               !Broadening value for NEGF method
INTEGER                        :: electrodesize(2)         !Supercell size for the electrode (same for left and right)
INTEGER                        :: scatteringsize(2)        !Supercell size for the centre scattering region
REAL (KIND=dp)                 :: electrodervector(3)      !R vector for the electrode in the real space
REAL (KIND=dp), ALLOCATABLE    :: scatteringcoor(:,:)      !Coordinate of atoms in the scattering centre
REAL (KIND=dp), ALLOCATABLE    :: electrodecoor(:,:)       !Coordinate of atoms in the electrode
REAL (KIND=dp)                 :: realrvector(3)           !R vector in the real space
REAL (KIND=dp)                 :: factor                   !Coefficient for the DOS with 2D Tetrahedron method
INTEGER                        :: kindex(3)                !k index for the triangle
REAL (KIND=dp)                 :: atomcoordinate(3,2)      !Coodinate of atom in the unit cell
REAL (KIND=dp)                 :: pi                       !Constant pi
REAL (KIND=dp)                 :: habr                     !Constant hbar (Unit: eV*s)
REAL (KIND=dp)                 :: kBT                      !Boltzmann constant (Unit: eV/Kelvin)
REAL (KIND=dp)                 :: conductancequantum       !2e^2/h in SI units (S)
REAL (KIND=dp)                 :: voltagepoint             !Actual voltage for the I-V curve
REAL (KIND=dp)                 :: integrationweight        !Trapezoidal weight for the I-V integration
REAL (KIND=dp)                 :: temperature              !Temperature (Unit: Kelvin)
REAL (KIND=dp)                 :: directcoordinate(3)      !Direct coordinate read from POSCAR
CHARACTER (LEN=100)            :: species                  !Chemical symbols read from POSCAR
REAL (KIND=dp)                 :: firstneighbour           !Distance for the first neighbour atom pair
TYPE (neighbour), ALLOCATABLE  :: firstlist(:)             !Variable to store the first neighbour bonding pair
INTEGER                        :: nfirstbond               !Number of the first neighbour bonding pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
COMPLEX (KIND=dp)              :: transcoefficient         !Sum of diagonal term of transmission matrix
COMPLEX (KIND=dp), ALLOCATABLE :: alltranscoefficient(:)   !Sum of diagonal term of transmission matrix at different energy point
COMPLEX (KIND=dp), ALLOCATABLE :: conductivity(:)          !Total Charge conductivity on all k points at different energy point
COMPLEX (KIND=dp), ALLOCATABLE :: ivcurve(:,:)             !I-V Curve data under different voltage difference on all k points
INTEGER                        :: timer(2)                 !Time counter
INTEGER                        :: timerate                 !Rate of timer

CALL SYSTEM_CLOCK(timer(1), timerate)

!Parameterization
pi = DACOS(-1.0d0)
habr = 6.582119d-16
kBT = 8.61733328d-5
conductancequantum = 7.748091729d-5
delta = 1.0d-1
hopping = -2.7d0

OPEN (UNIT=3, FILE='Graphene.vasp', STATUS='OLD', IOSTAT=k)
OPEN (UNIT=4, FILE='Conductivity_along_x_axis.dat', STATUS='REPLACE')
OPEN (UNIT=7, FILE='I_V_Curve.dat', STATUS='REPLACE')
OPEN (UNIT=8, FILE='Duration.dat', STATUS='REPLACE')

!Read the VASP/POSCAR header before the parameter lines with colons.
READ (UNIT=3, FMT=*, IOSTAT=k) scalingfactor
READ (UNIT=3, FMT='(A)', IOSTAT=k) str
READ (UNIT=3, FMT=*, IOSTAT=k) latticeinrealspace(1,:)
READ (UNIT=3, FMT=*, IOSTAT=k) latticeinrealspace(2,:)
READ (UNIT=3, FMT=*, IOSTAT=k) latticeinrealspace(3,:)
latticeinrealspace = TRANSPOSE(latticeinrealspace)*scalingfactor
READ (UNIT=3, FMT=*, IOSTAT=k) species
READ (UNIT=3, FMT=*, IOSTAT=k) natom
IF (natom /= 2) THEN
   WRITE (UNIT=8, FMT='(A)') 'ERROR: this graphene NEGF code requires exactly two basis atoms'
   STOP
END IF
READ (UNIT=3, FMT='(A)', IOSTAT=k) str
DO i = 1, natom, 1
   READ (UNIT=3, FMT=*, IOSTAT=k) directcoordinate
   atomcoordinate(:,i) = MATMUL(latticeinrealspace,directcoordinate)
END DO
IF (k /= 0) THEN
   WRITE (UNIT=8, FMT='(A)') 'ERROR: failed to read the structure header'
   STOP
END IF
firstneighbour = DSQRT(SUM((atomcoordinate(:,1)-atomcoordinate(:,2))**2))

!Calculating the lattice vector of unit cell in the reciprocal space
CALL KSPACE(latticeinrealspace,latticeinkspace)

!Obtaining the first neighbour bonding list
CALL NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nfirstbond,firstlist,firstneighbour,delta)

!Reading parameters and calculating the coordinates of k points for DOS
ALLOCATE (onsite(natom))
onsite = 0.0d0
DO WHILE (k == 0)
         READ (UNIT=3, FMT='(a)', IOSTAT=k) str
         str = ADJUSTL(str)
         i = INDEX(str,':')
         IF (i /= 0) THEN
            SELECT CASE(str(1:i-1))
                   CASE('onsite')
                       READ (UNIT=str(i+1:), FMT=*) onsite
                   CASE('Energy range for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) energyrange
                   CASE('Energy point for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) numenergypoint
                   CASE('k point mesh for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) kmesh
                   CASE('Temperature for I-V Curve')
                       READ (UNIT=str(i+1:), FMT=*) temperature
                   CASE('Voltage range for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) voltagerange
                   CASE('Voltage point for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) numvoltagepoint
                   CASE('broadening value for NEGF method')
                       READ (UNIT=str(i+1:), FMT=*) broadening
                   CASE('Supercell for the electrode')
                       READ (UNIT=str(i+1:), FMT=*) electrodesize
                   CASE('Supercell for the central scattering region')
                       READ (UNIT=str(i+1:), FMT=*) scatteringsize
            END SELECT
         END IF
END DO
!
IF (kmesh(1) /= 1) THEN
   WRITE (UNIT=8, FMT='(A)') 'ERROR: NEGF transport along x uses only the transverse k mesh; set kmesh(1)=1'
   STOP
END IF
IF (electrodesize(2) /= scatteringsize(2)) THEN
   WRITE (UNIT=8, FMT='(A)') 'ERROR: electrode and scattering-region transverse supercell sizes must match'
   STOP
END IF

!!Building up the supercell for central scattering region and electrodes
ALLOCATE (electrodecoor(3,electrodesize(1)*electrodesize(2)*2))
ALLOCATE (scatteringcoor(3,scatteringsize(1)*scatteringsize(2)*2))
DO i = 1, electrodesize(1), 1
   DO j = 1, electrodesize(2), 1
      electrodervector = (i-1)*latticeinrealspace(:,1)+(j-1)*latticeinrealspace(:,2)
      electrodecoor(:,(i-1)*electrodesize(2)*2+(j-1)*2+1) = electrodervector+atomcoordinate(:,1)
      electrodecoor(:,(i-1)*electrodesize(2)*2+(j-1)*2+2) = electrodervector+atomcoordinate(:,2)
   END DO
END DO
DO i = 1, scatteringsize(1), 1
   DO j = 1, scatteringsize(2), 1
      realrvector = (i-1)*latticeinrealspace(:,1)+(j-1)*latticeinrealspace(:,2)
      scatteringcoor(:,(i-1)*scatteringsize(2)*2+(j-1)*2+1) = realrvector+atomcoordinate(:,1)
      scatteringcoor(:,(i-1)*scatteringsize(2)*2+(j-1)*2+2) = realrvector+atomcoordinate(:,2)
   END DO
END DO
!
!Generating k point mesh
ALLOCATE (kpoint(3,kmesh(2)))
kpoint = 0.0d0
DO j = 1, kmesh(2), 1
   kpoint(:,j) = (DBLE(j)-0.5d0)/DBLE(kmesh(2))*latticeinkspace(:,2)/DBLE(scatteringsize(2))
END DO
!
!Calculating the coefficient of the transmission
ALLOCATE (energypoint(numenergypoint))
DO i = 1, numenergypoint, 1
   energypoint(i) = energyrange(1)+DBLE(i-1)*(energyrange(2)-energyrange(1))/DBLE(MAX(numenergypoint-1,1))
END DO
ALLOCATE (alltranscoefficient(numenergypoint))
alltranscoefficient = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, kmesh(2), 1
   DO j = 1, numenergypoint, 1
      CALL TRANSMISSION(kpoint(:,i),energypoint(j),nfirstbond,firstlist,onsite,hopping,electrodesize,&
                        scatteringsize,electrodervector,scatteringcoor,electrodecoor,latticeinrealspace,&
                        firstneighbour,delta,broadening,transcoefficient)
      alltranscoefficient(j) = alltranscoefficient(j)+transcoefficient
   END DO
END DO
alltranscoefficient = alltranscoefficient/REAL(kmesh(2), KIND=dp)
!
OPEN (UNIT=9, FILE='transmission.dat', STATUS='replace')
WRITE (UNIT=9, FMT='(A)') 'Energy (eV) Transmission T(E)'
DO i = 1, numenergypoint, 1
   WRITE (UNIT=9, FMT='(F15.8,3X,E15.8)') energypoint(i), REAL(alltranscoefficient(i))
END DO
CLOSE (UNIT=9)
!Outputing the charge conductivity
ALLOCATE (conductivity(numenergypoint))
conductivity = alltranscoefficient*conductancequantum
WRITE (UNIT=4, FMT='(A)') 'Energy (eV) Landauer conductance G(E) (S)'
DO i = 1, numenergypoint, 1
   WRITE (UNIT=4, FMT='(F15.8,3X,E15.8,3X,E15.8)') energypoint(i), REAL(conductivity(i)), AIMAG(conductivity(i))
END DO
!
!Outputing the I-V Curve
ALLOCATE (ivcurve(2,numvoltagepoint))
ivcurve = CMPLX(0.0, 0.0, KIND=dp)
inter(5) = (energyrange(2)-energyrange(1))/DBLE(MAX(numenergypoint-1,1))
DO i = 1, numvoltagepoint, 1
   voltagepoint = voltagerange(1)+DBLE(i-1)*(voltagerange(2)-voltagerange(1))/DBLE(MAX(numvoltagepoint-1,1))
   ivcurve(1,i) = CMPLX(voltagepoint, 0.0, KIND=dp)
   inter(1) = 0.5d0*voltagepoint
   inter(2) = -0.5d0*voltagepoint
   DO j = 1, numenergypoint, 1
      inter(3) = (energypoint(j)-inter(1))/(kBT*temperature)
      inter(4) = (energypoint(j)-inter(2))/(kBT*temperature)
      IF (inter(3) > 7.0d2) THEN
         inter(3) = 0.0d0
      ELSE IF (inter(3) < -7.0d2) THEN
         inter(3) = 1.0d0
      ELSE
         inter(3) = 1.0d0/(EXP(inter(3))+1.0d0)
      END IF
      IF (inter(4) > 7.0d2) THEN
         inter(4) = 0.0d0
      ELSE IF (inter(4) < -7.0d2) THEN
         inter(4) = 1.0d0
      ELSE
         inter(4) = 1.0d0/(EXP(inter(4))+1.0d0)
      END IF
      IF (j == 1 .OR. j == numenergypoint) THEN
         integrationweight = 0.5d0
      ELSE
         integrationweight = 1.0d0
      END IF
      ivcurve(2,i) = ivcurve(2,i)+alltranscoefficient(j)*(inter(3)-inter(4))*inter(5)*integrationweight
   END DO
   ivcurve(2,i) = ivcurve(2,i)*conductancequantum
END DO
DO i = 1, numvoltagepoint, 1
   WRITE (UNIT=7, FMT='(F15.8,3X,E15.8,3X,E15.8)') REAL(ivcurve(1,i)), REAL(ivcurve(2,i)), AIMAG(ivcurve(2,i))
END DO
!

CALL SYSTEM_CLOCK(timer(2))
WRITE (UNIT=8, FMT='(A11,F20.8,A8)') 'Duration is',REAL(timer(2)-timer(1))/timerate, 'seconds.'

DEALLOCATE (electrodecoor)
DEALLOCATE (scatteringcoor)
DEALLOCATE (firstlist)
DEALLOCATE (onsite)
DEALLOCATE (energypoint)
DEALLOCATE (kpoint)
DEALLOCATE (alltranscoefficient)
DEALLOCATE (conductivity)
DEALLOCATE (ivcurve)

CLOSE (UNIT=3)
CLOSE (UNIT=4)
CLOSE (UNIT=7)
CLOSE (UNIT=8)

STOP
END PROGRAM TIGHTBINDINGFORGRAPHENE
