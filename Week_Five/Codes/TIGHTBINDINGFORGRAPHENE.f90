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
     REAL (KIND=dp)            :: uvector(3)               !Unit bonding vector from atom i to atom j
     INTEGER                   :: chirality                !Chirality for spin orbit coupling term
END TYPE neighbour

CONTAINS
SUBROUTINE NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nbond,bondlist,distance1,distance2,delta,order)

INTEGER                        :: i, j, k
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: atomcoordinate(3,2)      !Coodinate of atom in the unit cell
INTEGER                        :: natom                    !Total number of atom in the unit cell
TYPE (neighbour), ALLOCATABLE  :: bondlist(:)              !Variable to store the first neighbour bonding pair
INTEGER                        :: nbond                    !Number of the first neighbour bonding pair
REAL (KIND=dp)                 :: distance1                !Distance for the first neighbour atom pair
REAL (KIND=dp)                 :: distance2                !Distance for the second neighbour atom pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
INTEGER                        :: order                    !Searching order of the neighbour
INTEGER                        :: n1, n2, n3               !Variables to compose the R vector in the real space
TYPE (neighbour), ALLOCATABLE  :: secbondlist(:)           !Variable to store the second neighbour bonding pair
INTEGER                        :: secnbond                 !Number of the second neighbour bonding pair
INTEGER                        :: bondindex                !Number counter of the first neighbour atom pair
REAL (KIND=dp)                 :: rcell(3)                 !Variable to store the R vector in the real space
REAL (KIND=dp)                 :: atomdistance             !Distance between each atom pair
REAL (KIND=dp)                 :: vector1(3), vector2(3)   !Variables between main and subroutine codes
REAL (KIND=dp)                 :: cross(3)                 !Variables between main and subroutine codes

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
               IF (ABS(atomdistance-distance1) <= delta) THEN
                  bondindex = bondindex+1
                  bondlist(bondindex)%atomi = i
                  bondlist(bondindex)%atomj = j
                  bondlist(bondindex)%region = atomdistance
                  bondlist(bondindex)%rvector = atomcoordinate(:,i)-atomcoordinate(:,j)+rcell
                  bondlist(bondindex)%uvector = bondlist(bondindex)%rvector/DSQRT(SUM(bondlist(bondindex)%rvector**2))
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

IF (order==2) THEN
   IF (ALLOCATED(secbondlist)) DEALLOCATE (secbondlist)
   ALLOCATE (secbondlist(natom**2*9))
   
   secnbond = 0
   bondindex = 0
   
   DO i = 1, natom, 1
      DO j = 1, natom, 1
         DO n1 = -1, 1, 1
            DO n2 = -1, 1, 1
               DO n3 = -1, 1, 1
                  rcell = n1*latticeinrealspace(:,1)+n2*latticeinrealspace(:,2)+n3*latticeinrealspace(:,3)
                  atomdistance = DSQRT(SUM((atomcoordinate(:,i)-atomcoordinate(:,j)+rcell)**2))
                  IF (ABS(atomdistance-distance2) <= delta) THEN
                     bondindex = bondindex+1
                     secbondlist(bondindex)%atomi = i
                     secbondlist(bondindex)%atomj = j
                     secbondlist(bondindex)%region = atomdistance
                     secbondlist(bondindex)%rvector = atomcoordinate(:,i)-atomcoordinate(:,j)+rcell
                     secbondlist(bondindex)%uvector = secbondlist(bondindex)%rvector/DSQRT(SUM(secbondlist(bondindex)%rvector**2))
                     DO k = 1, nbond, 1
                        IF (bondlist(k)%atomi == i) THEN
                           vector1 = bondlist(k)%rvector
                           vector2 = secbondlist(bondindex)%rvector-bondlist(k)%rvector
                           IF (ABS(DSQRT(SUM(vector2**2))-distance1) <= delta) THEN
                              CALL CROSSPRODUCT(vector1,vector2,cross)
                              IF (cross(3) > 1.0d-5) THEN
                                 secbondlist(bondindex)%chirality = 1
                                 EXIT
                              ELSE IF (cross(3) < -1.0d-5) THEN
                                 secbondlist(bondindex)%chirality = -1
                                 EXIT
                              END IF
                           END IF
                        END IF
                     END DO
                  END IF
               END DO
            END DO
         END DO
      END DO
   END DO
   
   secnbond = bondindex
   
   BLOCK
      TYPE (neighbour), ALLOCATABLE :: templist(:)
      ALLOCATE (templist(secnbond))
      templist = secbondlist(1:secnbond)
      DEALLOCATE (secbondlist)
      CALL MOVE_ALLOC(FROM=templist, TO=bondlist)
   END BLOCK
END IF

RETURN
END SUBROUTINE NEIGHBOURHAMILTONIAN

END MODULE GEOMETRY

PROGRAM TIGHTBINDINGFORGRAPHENE

USE GEOMETRY

IMPLICIT NONE

INTEGER                        :: i, j, k, l
CHARACTER (LEN=100)            :: str1, str2               !Variable to store data from 'Graphene.vasp' file
REAL (KIND=dp)                 :: inter(5)                 !Variable for DOS calculation
REAL (KIND=dp)                 :: scalingfactor            !Scaling factor in 'Graphene.vasp' file
REAL (KIND=dp)                 :: latticeinrealspace(3,3)  !Lattice constant for unit cell in the real space
REAL (KIND=dp)                 :: latticeinkspace(3,3)     !Lattice constant for unit cell in the reciprocal space
INTEGER                        :: natom                    !Total number of atom in the unit cell
REAL (KIND=dp)                 :: kcentre(3)               !Centre of k circle mesh
INTEGER                        :: numkcircle               !Number of k circle mesh
REAL (KIND=dp)                 :: deltakradius             !Delta radius of k circle mesh
REAL (KIND=dp), ALLOCATABLE    :: deltaangle(:)            !Delta angle of k circle mesh
INTEGER                        :: numk(4)                  !Number of k point on each circle
INTEGER                        :: numkpoint                !Number of k point for spin texture
REAL (KIND=dp), ALLOCATABLE    :: kpoint(:,:)              !Coordinate k point for spin texture
COMPLEX (KIND=dp), ALLOCATABLE :: spintexture(:,:,:)       !Spin texture
REAL (KIND=dp)                 :: atomcoordinate(3,2)      !Coodinate of atom in the unit cell
REAL (KIND=dp)                 :: pi                       !Constant pi
COMPLEX (KIND=dp)              :: paulix(2,2)              !Pauli Matrix along x axis
COMPLEX (KIND=dp)              :: pauliy(2,2)              !Pauli Matrix along y axis
COMPLEX (KIND=dp)              :: pauliz(2,2)              !Pauli Matrix along z axis
REAL (KIND=dp)                 :: unitvectorx(3)           !Unit vector along x axis
REAL (KIND=dp)                 :: unitvectory(3)           !Unit vector along y axis
REAL (KIND=dp)                 :: unitvectorz(3)           !Unit vector along z axis
REAL (KIND=dp)                 :: firstneighbour           !Distance for the first neighbour atom pair
TYPE (neighbour), ALLOCATABLE  :: firstlist(:)             !Variable to store the first neighbour bonding pair
INTEGER                        :: nfirstbond               !Number of the first neighbour bonding pair
REAL (KIND=dp)                 :: secondneighbour          !Distance for the second neighbour atom pair
TYPE (neighbour), ALLOCATABLE  :: secondlist(:)            !Variable to store the second neighbour bonding pair
INTEGER                        :: nsecondbond              !Number of the second neighbour bonding pair
REAL (KIND=dp)                 :: delta                    !Error interval for the distance for first atom pair
INTEGER                        :: order                    !Searching order of the neighbour
REAL (KIND=dp)                 :: phase                    !Dot product between k in real and R in reciprocal spaces
COMPLEX (KIND=dp)              :: phasefactor              !Phase factor in the Hamiltonian
REAL (KIND=dp), ALLOCATABLE    :: onsite(:)                !Variable to store the onsite energy
REAL (KIND=dp)                 :: hopping                  !Hopping value with Unit of eV
REAL (KIND=dp)                 :: intrinsicsoc             !Intrinsic Spin Orbit Coupling strength
REAL (KIND=dp)                 :: rashbasoc                !Rashba SOC strength
REAL (KIND=dp)                 :: dresselhaussoc           !Dresselhaus SOC strength
COMPLEX (KIND=dp), ALLOCATABLE :: honsite(:,:)             !Matrix to store the onsite energy term
COMPLEX (KIND=dp), ALLOCATABLE :: hhopping(:,:)            !Matrix to store the first neighbour hopping term
COMPLEX (KIND=dp), ALLOCATABLE :: hsoc(:,:)                !Matrix to store the intrinsic spin orbit coupling (SOC) term
COMPLEX (KIND=dp), ALLOCATABLE :: hrashba(:,:)             !Matrix to store the Rashba SOC term
COMPLEX (KIND=dp), ALLOCATABLE :: hdresselhaus(:,:)        !Matrix to store the Dresselhaus SOC term
COMPLEX (KIND=dp)              :: tmpmatrixx(2,2)          !Matris to store the internal result along x axis
COMPLEX (KIND=dp)              :: tmpmatrixy(2,2)          !Matris to store the internal result along y axis
COMPLEX (KIND=dp)              :: tmpmatrixz(2,2)          !Matris to store the internal result along z axis
REAL (KIND=dp)                 :: tmpvector(3)             !Vector to store the internal result
COMPLEX (KIND=dp), ALLOCATABLE :: hamiltonian(:,:)         !Matrix to store the whole hamiltonian
INTEGER                        :: numoccupy                !Number of occupied states
COMPLEX (KIND=dp), ALLOCATABLE :: occrashbastate(:,:,:)    !Matrix to store the occupied states for Rashba system along the ky loop
COMPLEX (KIND=dp), ALLOCATABLE :: occdressstate(:,:,:) !Matrix to store the occupied states for dresselhaus system along the ky loop

REAL (KIND=dp), ALLOCATABLE    :: eigenvalue(:)            !Eigenvalue
INTEGER                        :: info                     !ZHEEV Variable
REAL (KIND=dp), ALLOCATABLE    :: rwork(:)                 !ZHEEV Variable
COMPLEX (KIND=dp), ALLOCATABLE :: work(:)                  !ZHEEV Variable
INTEGER                        :: lwork                    !ZHEEV Variable

COMPLEX (KIND=dp), ALLOCATABLE :: overlaplink(:,:)
COMPLEX (KIND=dp), ALLOCATABLE :: wilsonloop(:,:)
COMPLEX (KIND=dp), ALLOCATABLE :: tempwilson(:,:)
COMPLEX (KIND=dp), ALLOCATABLE :: wancenval(:)
COMPLEX (KIND=dp), ALLOCATABLE :: wanwork(:)
REAL (KIND=dp), ALLOCATABLE    :: wanphase(:)

!Parameterization
pi = DACOS(-1.0d0)
paulix = CMPLX(0.0, 0.0, KIND=dp)
paulix(1,2) = CMPLX(1.0, 0.0, KIND=dp)
paulix(2,1) = CMPLX(1.0, 0.0, KIND=dp)
pauliy = CMPLX(0.0, 0.0, KIND=dp)
pauliy(1,2) = CMPLX(0.0, -1.0, KIND=dp)
pauliy(2,1) = CMPLX(0.0, 1.0, KIND=dp)
pauliz = CMPLX(0.0, 0.0, KIND=dp)
pauliz(1,1) = CMPLX(1.0, 0.0, KIND=dp)
pauliz(2,2) = CMPLX(-1.0, 0.0, KIND=dp)
unitvectorx = 0.0_dp
unitvectorx(1) = 1.0_dp
unitvectory = 0.0_dp
unitvectory(2) = 1.0_dp
unitvectorz = 0.0_dp
unitvectorz(3) = 1.0_dp
scalingfactor = 2.46d0
latticeinrealspace = 0.0d0
latticeinrealspace(1,1) = 1.0d0*scalingfactor
latticeinrealspace(1,2) = 1.0d0*scalingfactor*DCOS(2.0d0*pi/3.0d0)
latticeinrealspace(2,2) = 1.0d0*scalingfactor*DSIN(2.0d0*pi/3.0d0)
latticeinrealspace(3,3) = 1.0d0*scalingfactor
firstneighbour = 1.42d0
delta = 1.0d-1
secondneighbour = DSQRT(firstneighbour**2+firstneighbour**2-2*firstneighbour*firstneighbour*DCOS(1.2d2/3.6d2*pi))
natom = 2
atomcoordinate = 0.0d0
atomcoordinate(1,1) = 2.0d0*latticeinrealspace(1,1)/3.0d0+1.0d0*latticeinrealspace(1,2)/3.0d0+0.0d0*latticeinrealspace(1,3)
atomcoordinate(2,1) = 2.0d0*latticeinrealspace(2,1)/3.0d0+1.0d0*latticeinrealspace(2,2)/3.0d0+0.0d0*latticeinrealspace(2,3)
atomcoordinate(3,1) = 2.0d0*latticeinrealspace(3,1)/3.0d0+1.0d0*latticeinrealspace(3,2)/3.0d0+0.0d0*latticeinrealspace(3,3)
atomcoordinate(1,2) = 1.0d0*latticeinrealspace(1,1)/3.0d0+2.0d0*latticeinrealspace(1,2)/3.0d0+0.0d0*latticeinrealspace(1,3)
atomcoordinate(2,2) = 1.0d0*latticeinrealspace(2,1)/3.0d0+2.0d0*latticeinrealspace(2,2)/3.0d0+0.0d0*latticeinrealspace(2,3)
atomcoordinate(3,2) = 1.0d0*latticeinrealspace(3,1)/3.0d0+2.0d0*latticeinrealspace(3,2)/3.0d0+0.0d0*latticeinrealspace(3,3)
hopping = -2.7d0
numoccupy = 2
!

OPEN (UNIT=3, FILE='Graphene.vasp', STATUS='OLD', IOSTAT=k)
OPEN (UNIT=4, FILE='RASHBA_Spin_Texture.dat', STATUS='UNKNOWN')
OPEN (UNIT=7, FILE='DRESSELHAUS_Spin_Texture.dat', STATUS='UNKNOWN')
OPEN (UNIT=8, FILE='Wilsonloop_Rashba_System.dat', STATUS='UNKNOWN')
OPEN (UNIT=9, FILE='Wilsonloop_Dresselhaus_System.dat', STATUS='UNKNOWN')

!Calculating the lattice vector of unit cell in the reciprocal space
CALL KSPACE(latticeinrealspace,latticeinkspace)
!

!Obtaining the first neighbour bonding list
order = 1
CALL NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nfirstbond,firstlist,firstneighbour,0.0d0,delta,order)
!

!Obtaining the second neighbour bonding list
order = 2
CALL NEIGHBOURHAMILTONIAN(latticeinrealspace,atomcoordinate,natom,nsecondbond,secondlist,firstneighbour,secondneighbour,delta,order)
!

!Reading parameters and calculating the coordinates of k points for spin texture
ALLOCATE (onsite(natom))
onsite = 0.0d0
DO WHILE (k == 0)
         READ (UNIT=3, FMT='(a)', IOSTAT=k) str1
         str1 = ADJUSTL(str1)
         i = INDEX(str1,':')
         IF (i /= 0) THEN
            SELECT CASE(str1(1:i-1))
                   CASE('onsite')
                       READ (UNIT=str1(i+1:), FMT=*) onsite
                   CASE('Centre of k circle mesh')
                       READ (UNIT=str1(i+1:), FMT=*) kcentre
                   CASE('Number of k circle mesh')
                       READ (UNIT=str1(i+1:), FMT=*) numkcircle
                   CASE('Delta radius of k circle mesh')
                       READ (UNIT=str1(i+1:), FMT=*) deltakradius
                   CASE('Delta angle of k circle mesh')
                       str2 = str1(i+1:)
                   CASE('Intrinsic Spin Orbit Coupling strength')
                       READ (UNIT=str1(i+1:), FMT=*) intrinsicsoc
                   CASE('Rashba SOC strength')
                       READ (UNIT=str1(i+1:), FMT=*) rashbasoc
                   CASE('Dresselhaus SOC strength')
                       READ (UNIT=str1(i+1:), FMT=*) dresselhaussoc
                   CASE('k point mesh for wilson loop')
                       READ (UNIT=str1(i+1:), FMT=*) numk(1:2)
            END SELECT
         END IF
END DO
ALLOCATE (deltaangle(numkcircle))
READ (UNIT=str2, FMT=*) deltaangle
numkpoint = 0
DO i = 1, numkcircle, 1
   numkpoint = numkpoint+INT(3.6d2/deltaangle(i))
END DO
ALLOCATE (kpoint(3,numkpoint))
kpoint = 0.0d0
numk(3:4) = 0
DO i = 1, numkcircle, 1
   inter(1) = i*deltakradius
   numk(3) = INT(3.6d2/deltaangle(i))
   DO j = 1, numk(3), 1
      kpoint(1,numk(4)+j) = inter(1)*DCOS(j*deltaangle(i)/3.6d2*2.0d0*pi)
      kpoint(2,numk(4)+j) = inter(1)*DSIN(j*deltaangle(i)/3.6d2*2.0d0*pi)
   END DO
   numk(4) = numk(4)+numk(3)
END DO
inter(1) = DOT_PRODUCT(kcentre,latticeinkspace(1,:))
inter(2) = DOT_PRODUCT(kcentre,latticeinkspace(2,:))
inter(3) = DOT_PRODUCT(kcentre,latticeinkspace(3,:))
kpoint(1,:) = kpoint(1,:)+inter(1)
kpoint(2,:) = kpoint(2,:)+inter(2)
kpoint(3,:) = kpoint(3,:)+inter(3)
!

!Parameterizeing, diagonalising the Hamiltonian and calculating the spin texture
ALLOCATE (honsite(2*natom,2*natom))
ALLOCATE (hhopping(2*natom,2*natom))
ALLOCATE (hsoc(2*natom,2*natom))
ALLOCATE (hrashba(2*natom,2*natom))
ALLOCATE (hdresselhaus(2*natom,2*natom))
ALLOCATE (hamiltonian(2*natom,2*natom))
ALLOCATE (spintexture(6,2*natom,numkpoint))
spintexture = CMPLX(0.0, 0.0, KIND=dp)
honsite = CMPLX(0.0, 0.0, KIND=dp)
DO i = 1, natom, 1
   DO j = 1, 2, 1
      honsite((j-1)*natom+i,(j-1)*natom+i) = CMPLX(onsite(i), 0.0, KIND=dp)
   END DO
END DO
ALLOCATE (rwork(MAX(1,3*2*natom)))
lwork = MAX(1,3*2*natom-1)
ALLOCATE (work(lwork))
ALLOCATE (eigenvalue(2*natom))
DO i = 1, numkpoint, 1
      hhopping = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nfirstbond, 1
         IF (firstlist(j)%atomi > firstlist(j)%atomj) CYCLE
         phase = DOT_PRODUCT(kpoint(1:3,i),firstlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         hhopping(firstlist(j)%atomi,firstlist(j)%atomj) = hhopping(firstlist(j)%atomi,firstlist(j)%atomj)+hopping*phasefactor
         hhopping(firstlist(j)%atomi+natom,firstlist(j)%atomj+natom) = hhopping(firstlist(j)%atomi+natom,firstlist(j)%atomj+natom)&
                                                                       +hopping*phasefactor
      END DO
      hsoc = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nsecondbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,i),secondlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*intrinsicsoc*secondlist(j)%chirality*pauliz*phasefactor
         hsoc(secondlist(j)%atomi,secondlist(j)%atomj) = hsoc(secondlist(j)%atomi,secondlist(j)%atomj)+tmpmatrixz(1,1)
         hsoc(secondlist(j)%atomi+natom,secondlist(j)%atomj) = hsoc(secondlist(j)%atomi+natom,secondlist(j)%atomj)+tmpmatrixz(2,1)
         hsoc(secondlist(j)%atomi,secondlist(j)%atomj+natom) = hsoc(secondlist(j)%atomi,secondlist(j)%atomj+natom)+tmpmatrixz(1,2)
         hsoc(secondlist(j)%atomi+natom,secondlist(j)%atomj+natom) = hsoc(secondlist(j)%atomi+natom,secondlist(j)%atomj+natom)&
                                                                     +tmpmatrixz(2,2)
      END DO
      hrashba = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nfirstbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,i),firstlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         CALL CROSSPRODUCT(firstlist(j)%uvector,unitvectorz,tmpvector)
         tmpmatrixx = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*paulix*tmpvector(1)*phasefactor
         tmpmatrixy = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*pauliy*tmpvector(2)*phasefactor
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*pauliz*tmpvector(3)*phasefactor
         hrashba(firstlist(j)%atomi,firstlist(j)%atomj) = hrashba(firstlist(j)%atomi,firstlist(j)%atomj)+tmpmatrixx(1,1)&
                                                          +tmpmatrixy(1,1)+tmpmatrixz(1,1)
         hrashba(firstlist(j)%atomi+natom,firstlist(j)%atomj) = hrashba(firstlist(j)%atomi+natom,firstlist(j)%atomj)&
                                                                +tmpmatrixx(2,1)+tmpmatrixy(2,1)+tmpmatrixz(2,1)
         hrashba(firstlist(j)%atomi,firstlist(j)%atomj+natom) = hrashba(firstlist(j)%atomi,firstlist(j)%atomj+natom)&
                                                                +tmpmatrixx(1,2)+tmpmatrixy(1,2)+tmpmatrixz(1,2)
         hrashba(firstlist(j)%atomi+natom,firstlist(j)%atomj+natom) = hrashba(firstlist(j)%atomi+natom,firstlist(j)%atomj+natom)&
                                                                      +tmpmatrixx(2,2)+tmpmatrixy(2,2)+tmpmatrixz(2,2)
      END DO
      hdresselhaus = CMPLX(0.0, 0.0, KIND=dp)
      DO j = 1, nfirstbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,i),firstlist(j)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         tmpvector(1) = DOT_PRODUCT(unitvectorx,firstlist(j)%uvector)
         tmpmatrixx = paulix*tmpvector(1)
         tmpvector(2) = DOT_PRODUCT(unitvectory,firstlist(j)%uvector)
         tmpmatrixy = pauliy*tmpvector(2)
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*dresselhaussoc*(tmpmatrixx-tmpmatrixy)*phasefactor
         hdresselhaus(firstlist(j)%atomi,firstlist(j)%atomj) = hdresselhaus(firstlist(j)%atomi,firstlist(j)%atomj)+tmpmatrixz(1,1)
         hdresselhaus(firstlist(j)%atomi+natom,firstlist(j)%atomj) = hdresselhaus(firstlist(j)%atomi+natom,firstlist(j)%atomj)&
                                                                     +tmpmatrixz(2,1)
         hdresselhaus(firstlist(j)%atomi,firstlist(j)%atomj+natom) = hdresselhaus(firstlist(j)%atomi,firstlist(j)%atomj+natom)&
                                                                     +tmpmatrixz(1,2)
         hdresselhaus(firstlist(j)%atomi+natom,firstlist(j)%atomj+natom) = hdresselhaus(firstlist(j)%atomi+natom,&
                                                                           firstlist(j)%atomj+natom)+tmpmatrixz(2,2)
      END DO
      hamiltonian = honsite + hhopping + hsoc + hrashba
      CALL ZHEEV('V','U',2*natom,hamiltonian,2*natom,eigenvalue,work,lwork,rwork,info)
      DO j = 1, 2*natom, 1
         DO k = 1, natom, 1
            spintexture(1,j,i) = spintexture(1,j,i)+(DCONJG(hamiltonian(k,j))*paulix(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*paulix(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*paulix(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*paulix(2,2))*hamiltonian(k+natom,j)
            spintexture(2,j,i) = spintexture(2,j,i)+(DCONJG(hamiltonian(k,j))*pauliy(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliy(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*pauliy(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliy(2,2))*hamiltonian(k+natom,j)
            spintexture(3,j,i) = spintexture(3,j,i)+(DCONJG(hamiltonian(k,j))*pauliz(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliz(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*pauliz(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliz(2,2))*hamiltonian(k+natom,j)
         END DO
      END DO
      hamiltonian = honsite + hhopping + hsoc + hdresselhaus
      CALL ZHEEV('V','U',2*natom,hamiltonian,2*natom,eigenvalue,work,lwork,rwork,info)
      DO j = 1, 2*natom, 1
         DO k = 1, natom, 1
            spintexture(4,j,i) = spintexture(4,j,i)+(DCONJG(hamiltonian(k,j))*paulix(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*paulix(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*paulix(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*paulix(2,2))*hamiltonian(k+natom,j)
            spintexture(5,j,i) = spintexture(5,j,i)+(DCONJG(hamiltonian(k,j))*pauliy(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliy(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*pauliy(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliy(2,2))*hamiltonian(k+natom,j)
            spintexture(6,j,i) = spintexture(6,j,i)+(DCONJG(hamiltonian(k,j))*pauliz(1,1)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliz(2,1))*hamiltonian(k,j)&
                                 +(DCONJG(hamiltonian(k,j))*pauliz(1,2)&
                                 +DCONJG(hamiltonian(k+natom,j))*pauliz(2,2))*hamiltonian(k+natom,j)
         END DO
      END DO
END DO
!
!Rashba Spin texture
DO i = 1, 2*natom, 1
   DO j = 1, numkpoint, 1
      WRITE (UNIT=4, FMT='(6(F15.8,3X))') kpoint(1:3,j), REAL(spintexture(1:3,i,j))
   END DO
   WRITE (UNIT=4, FMT=*)
END DO
!

!Dresselhaus Spin texture
DO i = 1, 2*natom, 1
   DO j = 1, numkpoint, 1
      WRITE (UNIT=7, FMT='(6(F15.8,3X))') kpoint(1:3,j), REAL(spintexture(4:6,i,j))
   END DO
   WRITE (UNIT=7, FMT=*)
END DO
!
DEALLOCATE (kpoint)
!Re-sampling the kpoint mesh for wilson loop calculation
ALLOCATE (kpoint(3,numk(1)*(numk(2)+1)))
kpoint = 0.0d0
DO i = 0, numk(1)-1, 1
   DO j = 0, numk(2), 1
      kpoint(:,i*(numk(2)+1)+j+1) = DBLE(i)*1.0d0/numk(1)*latticeinkspace(:,1)+DBLE(j)*1.0d0/numk(2)*latticeinkspace(:,2)&
                                  +0.0d0*latticeinkspace(:,3)
   END DO
END DO
!
!Parameterizeing, diagonalising the Hamiltonian and calculating the wilson loop
WRITE (UNIT=8, FMT=*) '# kx_fractional    WCC_Phase_1/2pi    WCC_Phase_2/2pi'
WRITE (UNIT=9, FMT=*) '# kx_fractional    WCC_Phase_1/2pi    WCC_Phase_2/2pi'
ALLOCATE(occrashbastate(4,numoccupy,numk(2)+1))
ALLOCATE(occdressstate(4,numoccupy,numk(2)+1))
ALLOCATE (wilsonloop(numoccupy,numoccupy))
ALLOCATE (overlaplink(numoccupy,numoccupy))
ALLOCATE (tempwilson(numoccupy,numoccupy))
ALLOCATE (wancenval(numoccupy))
ALLOCATE (wanwork(2*numoccupy))
ALLOCATE (wanphase(numoccupy))
DO i = 1, numk(1), 1
   DO j = 1, numk(2)+1, 1
      hhopping = CMPLX(0.0, 0.0, KIND=dp)
      DO k = 1, nfirstbond, 1
         IF (firstlist(k)%atomi > firstlist(k)%atomj) CYCLE
         phase = DOT_PRODUCT(kpoint(1:3,(i-1)*(numk(2)+1)+j),firstlist(k)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         hhopping(firstlist(k)%atomi,firstlist(k)%atomj) = hhopping(firstlist(k)%atomi,firstlist(k)%atomj)+hopping*phasefactor
         hhopping(firstlist(k)%atomi+natom,firstlist(k)%atomj+natom) = hhopping(firstlist(k)%atomi+natom,firstlist(k)%atomj+natom)&
                                                                       +hopping*phasefactor
      END DO
      hsoc = CMPLX(0.0, 0.0, KIND=dp)
      DO k = 1, nsecondbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,(i-1)*(numk(2)+1)+j),secondlist(k)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*intrinsicsoc*secondlist(k)%chirality*pauliz*phasefactor
         hsoc(secondlist(k)%atomi,secondlist(k)%atomj) = hsoc(secondlist(k)%atomi,secondlist(k)%atomj)+tmpmatrixz(1,1)
         hsoc(secondlist(k)%atomi+natom,secondlist(k)%atomj) = hsoc(secondlist(k)%atomi+natom,secondlist(k)%atomj)+tmpmatrixz(2,1)
         hsoc(secondlist(k)%atomi,secondlist(k)%atomj+natom) = hsoc(secondlist(k)%atomi,secondlist(k)%atomj+natom)+tmpmatrixz(1,2)
         hsoc(secondlist(k)%atomi+natom,secondlist(k)%atomj+natom) = hsoc(secondlist(k)%atomi+natom,secondlist(k)%atomj+natom)&
                                                                     +tmpmatrixz(2,2)
      END DO
      hrashba = CMPLX(0.0, 0.0, KIND=dp)
      DO k = 1, nfirstbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,(i-1)*(numk(2)+1)+j),firstlist(k)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         CALL CROSSPRODUCT(firstlist(k)%uvector,unitvectorz,tmpvector)
         tmpmatrixx = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*paulix*tmpvector(1)*phasefactor
         tmpmatrixy = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*pauliy*tmpvector(2)*phasefactor
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*rashbasoc*pauliz*tmpvector(3)*phasefactor
         hrashba(firstlist(k)%atomi,firstlist(k)%atomj) = hrashba(firstlist(k)%atomi,firstlist(k)%atomj)+tmpmatrixx(1,1)&
                                                          +tmpmatrixy(1,1)+tmpmatrixz(1,1)
         hrashba(firstlist(k)%atomi+natom,firstlist(k)%atomj) = hrashba(firstlist(k)%atomi+natom,firstlist(k)%atomj)&
                                                                +tmpmatrixx(2,1)+tmpmatrixy(2,1)+tmpmatrixz(2,1)
         hrashba(firstlist(k)%atomi,firstlist(k)%atomj+natom) = hrashba(firstlist(k)%atomi,firstlist(k)%atomj+natom)&
                                                                +tmpmatrixx(1,2)+tmpmatrixy(1,2)+tmpmatrixz(1,2)
         hrashba(firstlist(k)%atomi+natom,firstlist(k)%atomj+natom) = hrashba(firstlist(k)%atomi+natom,firstlist(k)%atomj+natom)&
                                                                      +tmpmatrixx(2,2)+tmpmatrixy(2,2)+tmpmatrixz(2,2)
      END DO
      hdresselhaus = CMPLX(0.0, 0.0, KIND=dp)
      DO k = 1, nfirstbond, 1
         phase = DOT_PRODUCT(kpoint(1:3,(i-1)*(numk(2)+1)+j),firstlist(k)%rvector)
         phasefactor = CMPLX(COS(phase), SIN(phase), KIND=dp)
         tmpvector(1) = DOT_PRODUCT(unitvectorx,firstlist(k)%uvector)
         tmpmatrixx = paulix*tmpvector(1)
         tmpvector(2) = DOT_PRODUCT(unitvectory,firstlist(k)%uvector)
         tmpmatrixy = pauliy*tmpvector(2)
         tmpmatrixz = CMPLX(0.0, 1.0, KIND=dp)*dresselhaussoc*(tmpmatrixx-tmpmatrixy)*phasefactor
         hdresselhaus(firstlist(k)%atomi,firstlist(k)%atomj) = hdresselhaus(firstlist(k)%atomi,firstlist(k)%atomj)+tmpmatrixz(1,1)
         hdresselhaus(firstlist(k)%atomi+natom,firstlist(k)%atomj) = hdresselhaus(firstlist(k)%atomi+natom,firstlist(k)%atomj)&
                                                                     +tmpmatrixz(2,1)
         hdresselhaus(firstlist(k)%atomi,firstlist(k)%atomj+natom) = hdresselhaus(firstlist(k)%atomi,firstlist(k)%atomj+natom)&
                                                                     +tmpmatrixz(1,2)
         hdresselhaus(firstlist(k)%atomi+natom,firstlist(k)%atomj+natom) = hdresselhaus(firstlist(k)%atomi+natom,&
                                                                           firstlist(k)%atomj+natom)+tmpmatrixz(2,2)
      END DO
      hamiltonian = honsite + hhopping + hsoc + hrashba
      CALL ZHEEV('V','U',2*natom,hamiltonian,2*natom,eigenvalue,work,lwork,rwork,info)
      occrashbastate(:,1,j) = hamiltonian(:,1)
      occrashbastate(:,2,j) = hamiltonian(:,2)
      hamiltonian = honsite + hhopping + hsoc + hdresselhaus
      CALL ZHEEV('V','U',2*natom,hamiltonian,2*natom,eigenvalue,work,lwork,rwork,info)
      occdressstate(:,1,j) = hamiltonian(:,1)
      occdressstate(:,2,j) = hamiltonian(:,2)
   END DO
   occrashbastate(:,:,numk(2)+1) = occrashbastate(:,:,1)
   occdressstate(:,:,numk(2)+1) = occdressstate(:,:,1)
   !Wilson loop for the Rashba system
   wilsonloop = CMPLX(0.0, 0.0, KIND=dp)
   wilsonloop(1,1) = (1.0_dp, 0.0_dp)
   wilsonloop(2,2) = (1.0_dp, 0.0_dp)
   DO j = 1, numk(2), 1
       ! Construct overlap matrix M_mn = <u_m(iky) | u_n(iky+1)>
       DO k = 1, numoccupy, 1
           DO l = 1, numoccupy, 1
               overlaplink(k,l) = DOT_PRODUCT(occrashbastate(:,k,j),occrashbastate(:,l,j+1))
           END DO
       END DO
       ! Matrix multiplication to accumulate the Wilson Loop product
       tempwilson = MATMUL(wilsonloop,overlaplink)
       wilsonloop = tempwilson
   END DO
   !Diagonalize the final unitary Wilson Loop matrix to get Wannier Charge Centers (WCC)
   CALL ZGEEV('N','N',numoccupy,wilsonloop,numoccupy,wancenval,tempwilson,1,tempwilson,1,wanwork,2*numoccupy,rwork,info)
   ! Convert complex eigenvalues to phases theta in [-0.5, 0.5)
   DO j = 1, numoccupy, 1
      wanphase(j) = ATAN2(AIMAG(wancenval(j)),REAL(wancenval(j)))/(2.0d0*pi)
   END DO
   WRITE(UNIT=8, FMT='(F15.8,3X,2(F15.8,3X))') DBLE(i-1)*1.0d0/numk(1), wanphase(1), wanphase(2)
   !Wilson loop for the Dresselhaus system
   wilsonloop = CMPLX(0.0, 0.0, KIND=dp)
   wilsonloop(1,1) = (1.0_dp, 0.0_dp)
   wilsonloop(2,2) = (1.0_dp, 0.0_dp)
   DO j = 1, numk(2), 1
       ! Construct overlap matrix M_mn = <u_m(iky) | u_n(iky+1)>
       DO k = 1, numoccupy, 1
           DO l = 1, numoccupy, 1
               overlaplink(k,l) = DOT_PRODUCT(occdressstate(:,k,j),occdressstate(:,l,j+1))
           END DO
       END DO
       ! Matrix multiplication to accumulate the Wilson Loop product
       tempwilson = MATMUL(wilsonloop,overlaplink)
       wilsonloop = tempwilson
   END DO
   !Diagonalize the final unitary Wilson Loop matrix to get Wannier Charge Centers (WCC)
   CALL ZGEEV('N','N',numoccupy,wilsonloop,numoccupy,wancenval,tempwilson,1,tempwilson,1,wanwork,2*numoccupy,rwork,info)
   ! Convert complex eigenvalues to phases theta in [-0.5, 0.5)
   DO j = 1, numoccupy, 1
      wanphase(j) = ATAN2(AIMAG(wancenval(j)),REAL(wancenval(j)))/(2.0d0*pi)
   END DO
   WRITE(UNIT=9, FMT='(F15.8,3X,2(F15.8,3X))') DBLE(i-1)*1.0d0/numk(1), wanphase(1), wanphase(2)
END DO
!


DEALLOCATE (kpoint)
DEALLOCATE (firstlist)
DEALLOCATE (secondlist)
DEALLOCATE (deltaangle)
DEALLOCATE (onsite)
DEALLOCATE (honsite)
DEALLOCATE (hhopping)
DEALLOCATE (hsoc)
DEALLOCATE (hrashba)
DEALLOCATE (hdresselhaus)
DEALLOCATE (hamiltonian)
DEALLOCATE (eigenvalue)
DEALLOCATE (spintexture)
DEALLOCATE (rwork)
DEALLOCATE (work)
DEALLOCATE (occrashbastate)
DEALLOCATE (occdressstate)
DEALLOCATE (wilsonloop)
DEALLOCATE (overlaplink)
DEALLOCATE (tempwilson)
DEALLOCATE (wancenval)
DEALLOCATE (wanwork)
DEALLOCATE (wanphase)

CLOSE (UNIT=3)
CLOSE (UNIT=4)
CLOSE (UNIT=7)
CLOSE (UNIT=8)
CLOSE (UNIT=9)

STOP
END PROGRAM TIGHTBINDINGFORGRAPHENE

