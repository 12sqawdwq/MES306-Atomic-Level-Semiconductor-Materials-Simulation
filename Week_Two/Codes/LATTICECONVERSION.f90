SUBROUTINE DOTPRODUCT(vector1,vector2,volume)

IMPLICIT NONE

INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15,14)
REAL (KIND=dp)     :: vector1(3), vector2(3), volume

volume = vector1(1)*vector2(1)+vector1(2)*vector2(2)+vector1(3)*vector2(3)

RETURN
END SUBROUTINE DOTPRODUCT

SUBROUTINE CROSSPRODUCT(vector1,vector2,result)

IMPLICIT NONE

INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15,14)
REAL (KIND=dp)     :: vector1(3), vector2(3), result(3)

result(1) = vector1(2)*vector2(3)-vector1(3)*vector2(2)
result(2) = vector1(3)*vector2(1)-vector1(1)*vector2(3)
result(3) = vector1(1)*vector2(2)-vector1(2)*vector2(1)

RETURN
END SUBROUTINE CROSSPRODUCT

SUBROUTINE KSPACE(latticeinrealspace,latticeinkspace)

IMPLICIT NONE

INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15,14)
REAL (KIND=dp)     :: latticeinrealspace(3,3)
REAL (KIND=dp)     :: latticeinkspace(3,3)
REAL (KIND=dp)     :: volume
REAL (KIND=dp)     :: cross(3)
REAL (KIND=dp)     :: pi

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

PROGRAM LATTICECONVERSION

IMPLICIT NONE

INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15,14)
CHARACTER (LEN=50) :: str
INTEGER            :: i, j
REAL (KIND=dp)     :: latticeinrealspace(3,3)
REAL (KIND=dp)     :: latticeinkspace(3,3)

OPEN (UNIT=3, FILE='INPUT.dat', STATUS='OLD')
READ (UNIT=3, FMT='(a)') str
i = INDEX (str,':')
str = ADJUSTL(str(i+1:))
OPEN (UNIT=4, FILE=TRIM(str), STATUS='OLD')
READ (UNIT=4, FMT=*)
READ (UNIT=4, FMT=*)
DO i = 1, 3, 1
   READ (UNIT=4, FMT=*) latticeinrealspace(:,i)
END DO

CALL KSPACE(latticeinrealspace,latticeinkspace)

OPEN(UNIT=7, FILE='kspace.dat', STATUS='UNKNOWN')
DO i = 1, 3, 1
   WRITE (UNIT=7, FMT='(3X,F15.10,3X,F15.10,3X,F15.10)') latticeinkspace(:,i)
END DO

CLOSE (UNIT=3)
CLOSE (UNIT=4)

STOP
END PROGRAM LATTICECONVERSION
