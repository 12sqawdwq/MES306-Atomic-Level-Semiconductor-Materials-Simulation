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

END MODULE GEOMETRY

PROGRAM TIGHTBINDINGFORGRAPHENE

USE GEOMETRY

IMPLICIT NONE

INTEGER                        :: i, j, k, l
CHARACTER (LEN=100)            :: str                      !Variable to store data from 'Graphene.vasp' file
REAL (KIND=dp)                 :: inter(5)                 !Variable for DOS calculation
REAL (KIND=dp)                 :: scalingfactor            !Scaling factor in 'Graphene.vasp' file
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: latticeinkspace(3,3)     !Lattice constant for unit cell in the reciprocal space
INTEGER                        :: natom                    !Total number of atom in the unit cell
INTEGER                        :: kmesh(2)                 !k point mesh for DOS
REAL (KIND=dp)                 :: energyrange(2)           !Energy range for DOS
REAL (KIND=dp), ALLOCATABLE    :: kpoint(:,:)              !Coordinate k point for DOS
INTEGER                        :: numenergypoint           !Number of energy point for DOS
REAL (KIND=dp)                 :: broadening               !Broadening value for DOS
REAL (KIND=dp), ALLOCATABLE    :: energystate(:,:)         !Energy state for DOS
REAL (KIND=dp)                 :: factor                   !Coefficient for the DOS with 2D Tetrahedron method
INTEGER                        :: kindex(3)                !k index for the triangle
REAL (KIND=dp), ALLOCATABLE    :: dos(:,:)                 !Total DOS (unit: States/eV)
REAL (KIND=dp)                 :: atomcoordinate(3,2)      !Coodinate of atom in the unit cell
REAL (KIND=dp)                 :: pi                       !Constant pi
REAL (KIND=dp)                 :: firstneighbour           !Distance for the first neighbour atom pair
TYPE (neighbour), ALLOCATABLE  :: firstlist(:)             !Variable to store the first neighbour bonding pair
INTEGER                        :: nfirstbond               !Number of the first neighbour bonding pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
REAL (KIND=dp)                 :: phase                    !Dot product between k in real and R in reciprocal spaces
COMPLEX (KIND=dp)              :: phasefactor              !Phase factor in the Hamiltonian
REAL (KIND=dp), ALLOCATABLE    :: onsite(:)                !Variable to store the onsite energy
REAL (KIND=dp)                 :: hopping                  !Hopping value with Unit of eV
COMPLEX (KIND=dp), ALLOCATABLE :: honsite(:,:)             !Matrix to store the onsite energy term
COMPLEX (KIND=dp), ALLOCATABLE :: hhopping(:,:)            !Matrix to store the first neighbour hopping term
COMPLEX (KIND=dp), ALLOCATABLE :: hamiltonian(:,:)         !Matrix to store the whole hamiltonian

REAL (KIND=dp), ALLOCATABLE    :: eigenvalue(:)            !Eigenvalue
INTEGER                        :: info                     !ZHEEV Variable
REAL (KIND=dp), ALLOCATABLE    :: rwork(:)                 !ZHEEV Variable
COMPLEX (KIND=dp), ALLOCATABLE :: work(:)                  !ZHEEV Variable
INTEGER                        :: lwork                    !ZHEEV Variable

!Parameterization
pi = DACOS(-1.0d0)
scalingfactor = 2.46d0
latticeinrealspace = 0.0d0
latticeinrealspace(1,1) = 1.0d0*scalingfactor
latticeinrealspace(1,2) = 1.0d0*scalingfactor*DCOS(2.0d0*pi/3.0d0)
latticeinrealspace(2,2) = 1.0d0*scalingfactor*DSIN(2.0d0*pi/3.0d0)
latticeinrealspace(3,3) = 1.0d0*scalingfactor
firstneighbour = 1.42d0
delta = 1.0d-1
natom = 2
atomcoordinate = 0.0d0
atomcoordinate(1,1) = 2.0d0*latticeinrealspace(1,1)/3.0d0+1.0d0*latticeinrealspace(1,2)/3.0d0+0.0d0*latticeinrealspace(1,3)
atomcoordinate(2,1) = 2.0d0*latticeinrealspace(2,1)/3.0d0+1.0d0*latticeinrealspace(2,2)/3.0d0+0.0d0*latticeinrealspace(2,3)
atomcoordinate(3,1) = 2.0d0*latticeinrealspace(3,1)/3.0d0+1.0d0*latticeinrealspace(3,2)/3.0d0+0.0d0*latticeinrealspace(3,3)
atomcoordinate(1,2) = 1.0d0*latticeinrealspace(1,1)/3.0d0+2.0d0*latticeinrealspace(1,2)/3.0d0+0.0d0*latticeinrealspace(1,3)
atomcoordinate(2,2) = 1.0d0*latticeinrealspace(2,1)/3.0d0+2.0d0*latticeinrealspace(2,2)/3.0d0+0.0d0*latticeinrealspace(2,3)
atomcoordinate(3,2) = 1.0d0*latticeinrealspace(3,1)/3.0d0+2.0d0*latticeinrealspace(3,2)/3.0d0+0.0d0*latticeinrealspace(3,3)
hopping = -2.7d0
!

OPEN (UNIT=3, FILE='Graphene.vasp', STATUS='OLD', IOSTAT=k)
OPEN (UNIT=4, FILE='DOS_Lorentz_Method.dat', STATUS='UNKNOWN')
OPEN (UNIT=7, FILE='DOS_Gaussian_Method.dat', STATUS='UNKNOWN')
OPEN (UNIT=8, FILE='DOS_2D_Tetrahedron_Method.dat', STATUS='UNKNOWN')

!Calculating the lattice vector of unit cell in the reciprocal space
CALL KSPACE(latticeinrealspace,latticeinkspace)
!

!Obtaining the first neighbour bonding list
CALL NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nfirstbond,firstlist,firstneighbour,delta)
!

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
                   CASE('k point mesh for DOS')
                       READ (UNIT=str(i+1:), FMT=*) kmesh
                   CASE('Energy range for DOS')
                       READ (UNIT=str(i+1:), FMT=*) energyrange
                   CASE('Energy point for DOS')
                       READ (UNIT=str(i+1:), FMT=*) numenergypoint
                   CASE('Broadening value for DOS')
                       READ (UNIT=str(i+1:), FMT=*) broadening
            END SELECT
         END IF
END DO
ALLOCATE (kpoint(3,kmesh(1)*kmesh(2)))
kpoint = 0.0d0
DO i = 1, kmesh(1), 1
   DO j = 1, kmesh(2), 1
      kpoint(1,(i-1)*kmesh(2)+j) = DBLE(i-1)/DBLE(kmesh(1))*latticeinkspace(1,1)+DBLE(j-1)/DBLE(kmesh(2))*latticeinkspace(1,2)
      kpoint(2,(i-1)*kmesh(2)+j) = DBLE(i-1)/DBLE(kmesh(1))*latticeinkspace(2,1)+DBLE(j-1)/DBLE(kmesh(2))*latticeinkspace(2,2)
   END DO
END DO
!

!Parameterizeing and diagonalising the Hamiltonian
ALLOCATE (honsite(natom,natom))
ALLOCATE (hhopping(natom,natom))
ALLOCATE (hamiltonian(natom,natom))
ALLOCATE (energystate(2,kmesh(1)*kmesh(2)))
honsite = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, natom, 1
   honsite(i,i) = CMPLX(onsite(i), 0.0, KIND=dp)
END DO
ALLOCATE (rwork(MAX(1,3*natom-2)))
lwork = MAX(1,3*natom-1)
ALLOCATE (work(lwork))
ALLOCATE (eigenvalue(natom))
DO i = 1, kmesh(1)*kmesh(2), 1
      hhopping = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nfirstbond, 1
         IF (firstlist(j)%atomi > firstlist(j)%atomj) CYCLE
         phase = DOT_PRODUCT(kpoint(1:3,i),firstlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         hhopping(firstlist(j)%atomi,firstlist(j)%atomj) = hhopping(firstlist(j)%atomi,firstlist(j)%atomj)+hopping*phasefactor
      END DO
   hamiltonian = honsite + hhopping
   CALL ZHEEV('V','U',natom,hamiltonian,natom,eigenvalue,work,lwork,rwork,info)
   energystate(:,i) = eigenvalue
END DO
!
ALLOCATE (dos(2,numenergypoint))
!Method One: Lorentz Broadening Method
dos = 0.0d0
DO i = 1, numenergypoint, 1
   dos(1,i) = energyrange(1)+DBLE(i-1)/(numenergypoint-1)*(energyrange(2)-energyrange(1))
   DO j = 1, kmesh(1)*kmesh(2), 1
      DO k = 1, natom, 1
         dos(2,i) = dos(2,i)+broadening/(4*(dos(1,i)-energystate(k,j))**2+broadening**2)
      END DO
   END DO
END DO
dos(2,:) = dos(2,:)*2/kmesh(1)/kmesh(2)/pi
DO i = 1, numenergypoint, 1
   WRITE (UNIT=4, FMT='(F15.8,3X,F15.8)') dos(:,i)
END DO
!

!Method Two: Gaussian Broadening Method
dos = 0.0d0
DO i = 1, numenergypoint, 1
   dos(1,i) = energyrange(1)+DBLE(i-1)/(numenergypoint-1)*(energyrange(2)-energyrange(1))
   DO j = 1, kmesh(1)*kmesh(2), 1
      DO k = 1, natom, 1
         dos(2,i) = dos(2,i)+EXP(-((dos(1,i)-energystate(k,j))/broadening)**2)
      END DO
   END DO
END DO
dos(2,:) = dos(2,:)*2/kmesh(1)/kmesh(2)/broadening/DSQRT(pi)
DO i = 1, numenergypoint, 1
   WRITE (UNIT=7, FMT='(F15.8,3X,F15.8)') dos(:,i)
END DO
!

!2D Tetrahedron Method
factor = 2.0d0/(DBLE(kmesh(1))*kmesh(2))
dos = 0.0d0
DO i = 1, numenergypoint, 1
   dos(1,i) = energyrange(1)+DBLE(i-1)/(numenergypoint-1)*(energyrange(2)-energyrange(1))
END DO
DO i = 1, kmesh(1)-1, 1
   DO j = 1, kmesh(2)-1, 1
      DO k = 1, natom, 1
         !Lower left triangle
         kindex(1) = (i-1)*kmesh(2)+j
         kindex(2) = i*kmesh(2)+j
         kindex(3) = (i-1)*kmesh(2)+j+1
         inter(2) = energystate(k,kindex(1))
         inter(3) = energystate(k,kindex(2))
         inter(4) = energystate(k,kindex(3))
         IF (inter(2) > inter(3)) THEN
            inter(5) = inter(2)
            inter(2) = inter(3)
            inter(3) = inter(5)
         END IF
         IF (inter(3) > inter(4)) THEN
            inter(5) = inter(3)
            inter(3) = inter(4)
            inter(4) = inter(5)
         END IF
         IF (inter(2) > inter(3)) THEN
            inter(5) = inter(2)
            inter(2) = inter(3)
            inter(3) = inter(5)
         END IF
         DO l = 1, numenergypoint, 1
            inter(1) = dos(1,l)
            IF (inter(1) >= inter(2) .AND. inter(1) <= inter(4)) THEN
               IF (inter(1) <= inter(3)) THEN
                  IF (ABS(inter(3)-inter(2)) > 1.0d-8 .AND. ABS(inter(4)-inter(2)) > 1.0d-8) THEN
                     dos(2,l) = dos(2,l)+factor*(inter(1)-inter(2))/((inter(3)-inter(2))*(inter(4)-inter(2)))
                  END IF
               ELSE
                  IF (ABS(inter(4)-inter(2)) > 1.0d-8 .AND. ABS(inter(4)-inter(3)) > 1.0d-8) THEN
                     dos(2,l) = dos(2,l)+factor*(inter(4)-inter(1))/((inter(4)-inter(2))*(inter(4)-inter(3)))
                  END IF
               END IF
            END IF
         END DO
         !
         !Upper right triangle
         kindex(1) = i*kmesh(2)+j
         kindex(2) = i*kmesh(2)+j+1
         kindex(3) = (i-1)*kmesh(2)+j+1
         inter(2) = energystate(k,kindex(1))
         inter(3) = energystate(k,kindex(2))
         inter(4) = energystate(k,kindex(3))
         IF (inter(2) > inter(3)) THEN
            inter(5) = inter(2)
            inter(2) = inter(3)
            inter(3) = inter(5)
         END IF
         IF (inter(3) > inter(4)) THEN
            inter(5) = inter(3)
            inter(3) = inter(4)
            inter(4) = inter(5)
         END IF
         IF (inter(2) > inter(3)) THEN
            inter(5) = inter(2)
            inter(2) = inter(3)
            inter(3) = inter(5)
         END IF
         DO l = 1, numenergypoint, 1
            inter(1) = dos(1,l)
            IF (inter(1) >= inter(2) .AND. inter(1) <= inter(4)) THEN
               IF (inter(1) <= inter(3)) THEN
                  IF (ABS(inter(3)-inter(2)) > 1.0d-8 .AND. ABS(inter(4)-inter(2)) > 1.0d-8) THEN
                     dos(2,l) = dos(2,l)+factor*(inter(1)-inter(2))/((inter(3)-inter(2))*(inter(4)-inter(2)))
                  END IF
               ELSE
                  IF (ABS(inter(4)-inter(2)) > 1.0d-8 .AND. ABS(inter(4)-inter(3)) > 1.0d-8) THEN
                     dos(2,l) = dos(2,l)+factor*(inter(4)-inter(1))/((inter(4)-inter(2))*(inter(4)-inter(3)))
                  END IF
               END IF
            END IF
         END DO
      END DO
   END DO
END DO
DO i = 1, numenergypoint, 1
   WRITE (UNIT=8, FMT='(F15.8,3X,F15.8)') dos(:,i)
END DO
!

DEALLOCATE (kpoint)
DEALLOCATE (firstlist)
DEALLOCATE (onsite)
DEALLOCATE (honsite)
DEALLOCATE (hhopping)
DEALLOCATE (hamiltonian)
DEALLOCATE (eigenvalue)
DEALLOCATE (energystate)
DEALLOCATE (dos)
DEALLOCATE (rwork)
DEALLOCATE (work)

CLOSE (UNIT=3)
CLOSE (UNIT=4)
CLOSE (UNIT=7)
CLOSE (UNIT=8)

STOP
END PROGRAM TIGHTBINDINGFORGRAPHENE

