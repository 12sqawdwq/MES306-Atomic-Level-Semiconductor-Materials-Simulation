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

INTEGER                        :: i, j, k
CHARACTER (LEN=100)            :: str                      !Variable to store data from 'Graphene.vasp' file
REAL (KIND=dp)                 :: inter(3)                 !Variable for k calculation
REAL (KIND=dp)                 :: scalingfactor            !Scaling factor in 'Graphene.vasp' file
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: latticeinkspace(3,3)     !Lattice constant for unit cell in the reciprocal space
INTEGER                        :: natom                    !Total number of atom in the unit cell
INTEGER                        :: nk                       !Number of k point along each k path
REAL (KIND=dp)                 :: kpoint(3,3)              !Coordinate of high symmetry k point
REAL (KIND=dp), ALLOCATABLE    :: kpath(:,:)               !Variable to store the coordinates of all k points
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
nk = 100
kpoint = 0.0d0
kpoint(1,2) = 1.0d0/3.0d0
kpoint(2,2) = 1.0d0/3.0d0
kpoint(1,3) = 5.0d-1
hopping = -2.7d0
!

OPEN (UNIT=3, FILE='Graphene.vasp', STATUS='OLD', IOSTAT=k)
OPEN (UNIT=4, FILE='bandstructure.dat', STATUS='UNKNOWN')

!Calculating the lattice vector of unit cell in the reciprocal space and coordinates of k points for band structure
CALL KSPACE(latticeinrealspace,latticeinkspace)
DO i = 1, 3, 1
   kpoint(:,i) = MATMUL(latticeinkspace,kpoint(:,i))
END DO
ALLOCATE (kpath(4+natom,2*nk))
kpath = 0.0d0
DO i = 1, 2, 1
   inter(1) = (kpoint(1,i+1)-kpoint(1,i))/DBLE(nk)
   inter(2) = (kpoint(2,i+1)-kpoint(2,i))/DBLE(nk)
   inter(3) = (kpoint(3,i+1)-kpoint(3,i))/DBLE(nk)
   DO j = 1, nk, 1
      kpath(1,(i-1)*nk+j) = kpoint(1,i)+ inter(1)*DBLE(j-1)
      kpath(2,(i-1)*nk+j) = kpoint(2,i)+ inter(2)*DBLE(j-1)
      kpath(3,(i-1)*nk+j) = kpoint(3,i)+ inter(3)*DBLE(j-1)
   END DO
END DO
DO i = 2, 2*nk, 1
   kpath(4,i) = kpath(4,i-1)+DSQRT(SUM((kpath(1:3,i)-kpath(1:3,i-1))**2))
END DO
!

OPEN(UNIT=7, FILE='kspace.dat', STATUS='UNKNOWN')
DO i = 1, 3, 1
   WRITE (UNIT=7, FMT='(3X,F15.10,3X,F15.10,3X,F15.10)') latticeinkspace(:,i)
END DO

!Obtaining the first neighbour bonding list
CALL NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nfirstbond,firstlist,firstneighbour,delta)
!

!Parameterizeing and diagonalising the Hamiltonian
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
            END SELECT
         END IF
END DO

ALLOCATE (honsite(natom,natom))
ALLOCATE (hhopping(natom,natom))
ALLOCATE (hamiltonian(natom,natom))
honsite = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, natom, 1
   honsite(i,i) = CMPLX(onsite(i), 0.0, KIND=dp)
END DO
ALLOCATE (rwork(MAX(1,3*natom-2)))
lwork = MAX(1,3*natom-1)
ALLOCATE (work(lwork))
ALLOCATE (eigenvalue(natom))
DO i = 1, 2*nk, 1
      hhopping = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nfirstbond, 1
         IF (firstlist(j)%atomi > firstlist(j)%atomj) CYCLE
         phase = DOT_PRODUCT(kpath(1:3,i),firstlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         hhopping(firstlist(j)%atomi,firstlist(j)%atomj) = hhopping(firstlist(j)%atomi,firstlist(j)%atomj)+hopping*phasefactor
      END DO
   hamiltonian = honsite + hhopping
   CALL ZHEEV('V','U',natom,hamiltonian,natom,eigenvalue,work,lwork,rwork,info)
   kpath(5:,i) = eigenvalue
END DO

DO i = 1, natom, 1
   DO j = 1, 2*nk, 1
      WRITE (UNIT=4, FMT='(F15.9,3X,F15.9)') kpath(4,j), kpath(4+i,j)
   END DO
   WRITE (UNIT=4, FMT=*)
END DO

DEALLOCATE (kpath)
DEALLOCATE (firstlist)
DEALLOCATE (onsite)
DEALLOCATE (honsite)
DEALLOCATE (hhopping)
DEALLOCATE (hamiltonian)
DEALLOCATE (eigenvalue)
DEALLOCATE (rwork)
DEALLOCATE (work)

CLOSE (UNIT=3)
CLOSE (UNIT=4)

STOP
END PROGRAM TIGHTBINDINGFORGRAPHENE

