      program intcont

!=============================================================================
!  CALCULATE ATOMIC CONTACTS BETWEEN TWO INTERFACES  
!  GROUP RESIDUES INTO 6 PRE-DEFINED GROUPS AND
!  AND GENERATE A 6 X 6 (SYMMETRIC) COMPLEMENTARY MATRIX  
!=============================================================================


      character(256)::pdb,intf1,intf2,lib
      integer::ires1(500),ires2(500)
      character(3)::res1(500),res2(500),atest(20)
      character(1)::ch1(500),ch2(500)
      character(4)::atom(25000)
      integer::ires(25000),iret
      character(3)::res(25000)
      character(1)::ch(25000)
      real::x(25000),y(25000),z(25000)
      character(3)::resic1(1000),resic2(1000)
      integer::icontmat(20,20),icontmat6(6,6)
      real::contmatf(20,20),contmatf6(6,6)
      real::contpref(20,20),cscore(20,20)

      call getarg(1,pdb)	! The PDB file contating two chains
      call getarg(2,intf1)	! Interface 1
      call getarg(3,intf2)	! Interface 2
      call getarg(4,lib)
      call system('rm fort.*')

!      lib='/tmp/x_bjowa/ProQDock/LIBR/contpref.mat'
 
      open (1,file=pdb,status='old')
      open (2,file=intf1,status='old')
      open (3,file=intf2,status='old')
      open (4,file=lib,status='old')

      do i = 1,20
      read(4,213,end=110)(contpref(i,j), j = 1,20)
      write(*,213)(contpref(i,j), j = 1,20)
      enddo      

110   continue

212   format(/)
213   format(20(f5.2,3x))

      ic1 = 0
      ic2 = 0

      do i = 1,500
      read(2,34,end=10)ires1(i),res1(i),ch1(i)
!      write(*,34)ires1(i),res1(i),ch1(i)
      ic1 = ic1 + 1
      enddo

10    continue

      do i = 1,500
      read(3,34,end=20)ires2(i),res2(i),ch2(i)
!      write(*,34)ires2(i),res2(i),ch2(i)
      ic2 = ic2 + 1
      enddo

20    continue

34    format(i3,1x,a3,1x,a1)

!      print*,ic1,ic2

      ic = 0
      do i = 1,25000
      read(1,32,end=30)atom(i),res(i),ch(i),ires(i),x(i),y(i),z(i)
!      write(*,32)atom(i),res(i),ch(i),ires(i),x(i),y(i),z(i)
      ic = ic + 1
      enddo

30    continue

32    format(12x,a4,1x,a3,1x,a1,i4,4x,3f8.3)

!      print*,ic
!==========================================================================================================================
!     CREATE THE COMPLEMENTATION MATRIX (OR CONTACT MAP) : THE MATRIX SHOULD BE SYMMETRIC 
!==========================================================================================================================

!========================================================================================================
!     Test CONVERTION aa strings to indexes here 
!========================================================================================================

      atest(1) = 'ILE'
      atest(2) = 'VAL'
      atest(3) = 'LEU'
      atest(4) = 'PHE'
      atest(5) = 'CYS'
      atest(6) = 'MET'
      atest(7) = 'ALA'
      atest(8) = 'GLY'
      atest(9) = 'THR'
      atest(10) = 'SER'
      atest(11) = 'TRP'
      atest(12) = 'TYR'
      atest(13) = 'PRO'
      atest(14) = 'HIS'
      atest(15) = 'GLU'
      atest(16) = 'GLN'
      atest(17) = 'ASP'
      atest(18) = 'ASN'
      atest(19) = 'LYS'
      atest(20) = 'ARG'

!      atest = 'GLN'

      do i = 1,20
      call aa2ind(atest(i),iret)
      write(*,85)atest(i),iret
      enddo

85    format(a3,2x,i5)
      
      distcut = 10.0

!========================================================================================================
!     INITIALIZE (BOTH) CONTACT MATRICES 
!========================================================================================================

       do i = 1,20 
            do j = 1,20
            icontmat(i,j) = 0
            contmatf(i,j) = 0.00
            enddo
       enddo

       do i = 1,6
            do j = 1,6
            icontmat6(i,j) = 0
            contmatf6(i,j) = 0.00
            enddo
       enddo

!========================================================================================================
!================================== CALCULATE INTERFACIAL ATOMIC CONTACTS HERE ===============================================    

      print*,ic1,ic2,ic

      icnt = 0
      icnt2 = 0

      do i = 1,ic1
           do j = 1,ic2
!                print*,ires1(i),res1(i),ch1(i),ires2(j),res2(j),ch2(j)
           idiag = 0
           idiag2 = 0
           icon = 0
                do k = 1,ic
                     if (ires1(i)==ires(k) .and. res1(i).eq.res(k) 
     &.and. ch1(i).eq.ch(k))then
                         do l = 1,ic
                           if (ires2(j)==ires(l) .and. 
     &res2(j).eq.res(l) .and. ch2(j).eq.ch(l))then
!============================================================================================================================
!================================= CB ONLY FOR NON-GLY AND CA FOR GLY =======================================================
!============================================================================================================================


!       print*,res(k),ires(k),ch(k),atom(k),x(k),y(k),z(k),'<=>',
!     &res(l),ires(l),ch(l),atom(l),x(l),y(l),z(l)



      iflag1 = 0
      iflag2 = 0

                  if (res(k).eq.'GLY'.and.atom(k)(2:3).eq.'CA')then
                  iflag1 = 1
                  elseif (res(k).ne.'GLY'.and.atom(k)(2:3).eq.'CB')then
                  iflag1 = 1
                  endif

                  if (res(l).eq.'GLY'.and.atom(l)(2:3).eq.'CA')then
                  iflag2 = 1
                  elseif (res(l).ne.'GLY'.and.atom(l)(2:3).eq.'CB')then
                  iflag2 = 1
                  endif

                  if (iflag1 == 1 .and. iflag2 == 1)then
                  goto 75
                  else
                  goto 175
                  endif

75    continue

!============================================================================================================================
                           dist = sqrt((x(k)-x(l))**2 + (y(k)-y(l))**2 
     &+ (z(k)-z(l))**2)
!              print*,dist
!              print*,res(k),atom(k),'<=>',res(l),atom(l),'     ',dist
                                      if (dist <= distcut)then   ! Number of Atomic Contacts between a pair of Residues 
                                      icon = icon + 1
!                         print*,res(k),atom(k),'<=>',res(l),atom(l)
                                      endif 
!============================================================================================================================
      write(132,514)iflag1,iflag2,res(k),atom(k),res(l),atom(l),dist,
     &distcut,icon
514   format(i1,2x,i1,2x,a3,2x,a4,5x,a3,2x,a4,2x,f8.3,2x,f8.3,2x,i10)
!============================================================================================================================
175      continue
                           endif
                         enddo
                     endif                           
                enddo
                if (icon >= 1)then
                write(31,96)ires1(i),res1(i),ch1(i),ires2(j),res2(j),
     &ch2(j),icon
         ig1 = 0
         jg1 = 0
                write(23,99)res1(i),res2(j)
                icnt = icnt + 1
                call aa2ind(res1(i),i1)
                call aa2ind(res2(j),j1)
!=============================== GROUP CONTACTS INTO 6 ==================================================

!        case 'R': return 1;
!        case 'K': return 1;
!        case 'D': return 2;
!        case 'E': return 2;
!        case 'H': return 3;
!        case 'F': return 3;
!        case 'W': return 3;
!        case 'Y': return 3;
!        case 'N': return 4;
!        case 'Q': return 4;
!        case 'S': return 4;
!        case 'T': return 4;
!        case 'A': return 5;
!        case 'I': return 5;
!        case 'L': return 5;
!        case 'M': return 5;
!        case 'V': return 5;
!        case 'C': return 5;
!        case 'G': return 6;
!        case 'P': return 6;

                if ((res1(i).eq.'ARG').or.(res1(i).eq.'LYS'))then
                ig1 = 1
                elseif ((res1(i).eq.'ASP').or.(res1(i).eq.'GLU'))then
                ig1 = 2
                elseif ((res1(i).eq.'HIS').or.(res1(i).eq.'PHE').or.
     &(res1(i).eq.'TYR').or.(res1(i).eq.'TRP'))then
                ig1 = 3
                elseif ((res1(i).eq.'ASN').or.(res1(i).eq.'GLN').or.
     &(res1(i).eq.'SER').or.(res1(i).eq.'THR'))then
                ig1 = 4
                elseif ((res1(i).eq.'ALA').or.(res1(i).eq.'VAL').or.
     &(res1(i).eq.'LEU').or.(res1(i).eq.'ILE').or.(res1(i).eq.'MET').or.
     &(res1(i).eq.'CYS'))then
                ig1 = 5
                elseif ((res1(i).eq.'GLY').or.(res1(i).eq.'PRO'))then
                ig1 = 6
                else 
                print*,'could not be grouped',res1(i)
                endif

                if ((res2(j).eq.'ARG').or.(res2(j).eq.'LYS'))then
                jg1 = 1
                elseif ((res2(j).eq.'ASP').or.(res2(j).eq.'GLU'))then
                jg1 = 2
                elseif ((res2(j).eq.'HIS').or.(res2(j).eq.'PHE').or.
     &(res2(j).eq.'TYR').or.(res2(j).eq.'TRP'))then
                jg1 = 3
                elseif ((res2(j).eq.'ASN').or.(res2(j).eq.'GLN').or.
     &(res2(j).eq.'SER').or.(res2(j).eq.'THR'))then
                jg1 = 4
                elseif ((res2(j).eq.'ALA').or.(res2(j).eq.'VAL').or.
     &(res2(j).eq.'LEU').or.(res2(j).eq.'ILE').or.(res2(j).eq.'MET').or.
     &(res2(j).eq.'CYS'))then
                jg1 = 5
                elseif ((res2(j).eq.'GLY').or.(res2(j).eq.'PRO'))then
                jg1 = 6
                else 
                print*,'could not be grouped',res2(j)
                endif

                if (ig1 /= 0 .and. jg1 /= 0)then
                icontmat6(ig1,jg1) = icontmat6(ig1,jg1) + 1
                icontmat6(jg1,ig1) = icontmat6(jg1,ig1) + 1
                icnt2 = icnt2 + 1
                      if (ig1 == jg1)then
                      idiag2 = 1
                      endif
!		print*,res1(i),'  ',res2(j),'  ',ig1,'  ',jg1
                endif

!=========================================================================================================
                 icontmat(i1,j1) = icontmat(i1,j1) + 1
                 icontmat(j1,i1) = icontmat(j1,i1) + 1
                 if (res1(i).eq.res2(j))then
                 idiag = 1
                 endif
                 if (idiag == 0 .and. idiag2 == 0)then
                 write(131,197)res1(i),res2(j),icnt,i1,j1,'----','-----'
                 elseif (idiag == 1 .and. idiag2 == 0)then
                 write(131,197)res1(i),res2(j),icnt,i1,j1,'DIAG','-----'
                 elseif (idiag == 0 .and. idiag2 == 1)then
                 write(131,197)res1(i),res2(j),icnt,i1,j1,'----','GDIAG'
                 elseif (idiag == 1 .and. idiag2 == 1)then
                 write(131,197)res1(i),res2(j),icnt,i1,j1,'DIAG','GDIAG'
                 endif
                endif
           enddo
      enddo

      print*,'uncorrected_count: ',icnt
      print*,'uncorrected_count_6: ',icnt2

!============================ CORRECT FOR THE DOUBLE COUNTNING OF DIAGONAL ELEMENTS ==============================

      do i = 1,20
         icontmat(i,i) = icontmat(i,i)/2
      enddo

      do i = 1,6
!	print*,iconmat6(i,i)
         icontmat6(i,i) = icontmat6(i,i)/2
      enddo

!============================ CORRECT COUNT =====================================================================

      icntc = 0

      do i = 1,20
         do j = 1,20     
             if (i >= j)then 
              icntc = icntc + icontmat(i,j)						! Contact map (in fraction)
             endif
         enddo
      enddo

      print*,'corrected_count: ',icntc

!=================================================================================================================
!============================ CORRECT COUNT =====================================================================

      icntc1 = 0

      do i = 1,6
         do j = 1,6
            if (i >= j)then
              icntc1 = icntc1 + icontmat6(i,j)						! Contact map (in fraction)
            endif
         enddo
      enddo

      print*,'corrected_count_6: ',icntc1

!=================================================================================================================

96    format(i3,2x,a3,2x,a1,5x,i3,2x,a3,2x,a1,5x,i10)
196   format(a3,2x,a3,2x,i5,2x,i5,2x,i5)
197   format(a3,2x,a3,2x,i5,2x,i5,2x,i5,2x,a4,2x,a5)
99    format(a3,2x,a3)

       itotc = 0

       print*,'----------------------------'

67     format(a3,2x,a3)
167    format(i3,2x,i3,2x,a3,2x,a3,2x,i5)
68     format(a3,2x,a3,2x,i5)
168    format(a3,2x,a3,2x,i5,2x,i5)

!======================================== CHECK SYMMETRY of the integer contact matrix ======================

       itot1 = 0
       Nc1 = 0

       do i = 1,20
            do j = (i+1),20
                 if (icontmat(i,j)==icontmat(j,i))then
                 Nc1 = Nc1 + 1
                 endif
            itot1 = itot1 + 1
            enddo
       enddo

       print*,Nc1,itot1

       if (Nc1 == itot1)then
       write(*,*) 'INTEGER CONTACT MATRIX IS SYMMETRIC'
       endif


79     format(a3,2x,a3)

!======================================== CHECK SYMMETRY of the integer contact matrix (6) ======================

       itot2 = 0
       Nc2 = 0

       do i = 1,6
            do j = (i+1),6
                 if (icontmat(i,j)==icontmat(j,i))then
                 Nc2 = Nc2 + 1
                 endif
            itot2 = itot2 + 1
            enddo
       enddo

!       print*,Nc1,itot1

       if (Nc2 == itot2)then
       write(*,*) 'INTEGER GROUP CONTACT MATRIX IS SYMMETRIC'
       endif



!=============================== GENERATE FRACTIONAL CONTACT MATRIX ===================================
!======================= & CHECK SUM of both matrices ==========================================================
       sumch = 0.000
       isum1 = 0

       do i = 1,20
            do j = 1,20
                 if (i >= j) then               ! Up diagonal / diagonal elements
                     if (icntc == 0)then
                     contmatf(i,j) = 0.000
                     else
                     contmatf(i,j) = float(icontmat(i,j))/float(icntc)				! Contact map (in fraction)
                     endif
                     if (i > j)then
                     contmatf(j,i) = contmatf(i,j)
                     endif
                     isum1 = isum1 + icontmat(i,j)						! Contact map (in fraction)
!                    write(*,93)i,j,icontmat(i,j),contmatf(i,j)
                     sumch = sumch + contmatf(i,j)
                 endif
            enddo
       enddo

       write(*,*)'sum_int = ',isum1,'sum_frac = ',sumch

93     format(i3,2x,i3,2x,i10,2x,f10.5)

!=============================== GENERATE FRACTIONAL CONTACT MATRIX ===================================
!======================= & CHECK SUM of both matrices ==========================================================
       sumch2 = 0.000
       isum2 = 0

       do i = 1,6
            do j = 1,6
               if (i >= j)then
                 if (icntc1 == 0)then
                 contmatf6(i,j) = 0.000
                 else
                 contmatf6(i,j) = float(icontmat6(i,j))/float(icntc1)				! Contact map (in fraction)
                 endif
                 if (i > j)then
                 contmatf6(j,i) = contmatf6(i,j)
                 endif
                 isum2 = isum2 + icontmat6(i,j)						! Contact map (in fraction)
!                 write(*,93)i,j,icontmat(i,j),contmatf(i,j)
                 sumch2 = sumch2 + contmatf6(i,j)
               endif
            enddo
       enddo

       write(*,*)'sum_int = ',isum2,'sum_frac = ',sumch2


!======================================== CHECK SYMMETRY of the fractional contact matrix ==================
!===========================================================================================================

       itot2 = 0
       Nc2 = 0

       do i = 1,20
            do j = (i+1),20
                 if (contmatf(i,j)==contmatf(j,i))then
                 Nc2 = Nc2 + 1
                 endif
            itot2 = itot2 + 1
            enddo
       enddo

       if (Nc2 == itot2)then
       write(*,*) 'FRACTIONAL CONTACT MATRIX IS SYMMETRIC'
       endif

!======================================== CHECK SYMMETRY of the fractional contact matrix ==================
!===========================================================================================================

       itot2 = 0
       Nc2 = 0

       do i = 1,6
            do j = (i+1),6
                 if (contmatf6(i,j)==contmatf6(j,i))then
                 Nc2 = Nc2 + 1
                 endif
            itot2 = itot2 + 1
            enddo
       enddo

       if (Nc2 == itot2)then
       write(*,*) 'FRACTIONAL GROUP CONTACT MATRIX IS SYMMETRIC'
       endif
!       print*,Nc2,itot2

!============================================================================================================

!       print*,'~~~~~~~~~~~',icontmat(20,5)

       do i = 1,20
       write(*,81)(icontmat(i,j), j = 1,20)
       write(35,81)(icontmat(i,j), j = 1,20)
       enddo

81     format(20(i3,1x))

       do i = 1,20
       write(*,82)(contmatf(i,j), j = 1,20)
       write(36,82)(contmatf(i,j), j = 1,20)
       enddo

       do i = 1,20
           do j = 1,20 
                cscore(i,j) = contpref(i,j)*contmatf(i,j)
           enddo
       enddo

       print*,''
       print*,'CONTACT SCORE MATRIX:'
       print*,''

       do i = 1,20
       write(*,82)(cscore(i,j), j = 1,20)
       write(37,82)(cscore(i,j), j = 1,20)
       enddo

!===========================================================================================================

       itot3 = 0
       Nc3 = 0

       do i = 1,20
            do j = (i+1),20
                 if (cscore(i,j)==cscore(j,i))then
                 Nc3 = Nc3 + 1
                 endif
            itot3 = itot3 + 1
            enddo
       enddo

       if (Nc3 == itot3)then
       write(*,*) 'CONTACT PREFERENCE MATRIX IS SYMMETRIC'
       endif
!       print*,Nc2,itot2

!============================================================================================================

82     format(20(f8.5,1x))

       do i = 1,6
       write(*,181)(icontmat6(i,j), j = 1,6)
       write(135,181)(icontmat6(i,j), j = 1,6)
       enddo

181     format(6(i3,1x))

       do i = 1,6
       write(*,182)(contmatf6(i,j), j = 1,6)
       write(136,182)(contmatf6(i,j), j = 1,6)
       enddo

182     format(6(f8.5,1x))

      endprogram intcont

      subroutine aa2ind(aainp,indret)
!==========================================================================================================================
!     CREATE THE COMPLEMENTATION MATRIX (OR CONTACT MAP) : THE MATRIX SHOULD BE SYMMETRIC 
!==========================================================================================================================
      character(3)::aainp,aa(20)
      integer::inda(20)
      
!      aa = (/'GLY','ALA','VAL','LEU','ILE','PHE','TYR','TRP','SER',
!     &'THR','CYS','MET','ASP','GLU','ASN','GLN','LYS','ARG','PRO',
!     &'HIS'/)

!===========================================================================================================================
! Preferred Order :  I   V   L   F   C   M   A   G   T   S   W   Y   P   H   E   Q  D  N   K  R
!===========================================================================================================================

      aa = (/'ILE','VAL','LEU','PHE','CYS','MET','ALA','GLY','THR',
     &'SER','TRP','TYR','PRO','HIS','GLU','GLN','ASP','ASN','LYS',
     &'ARG'/)
      
      do i = 1,20
      inda(i) = i
!      write(*,281)inda(i),aa(i)
            if (aainp.eq.aa(i))then
            indret = i
            endif
      enddo

281   format(i3,2x,a3)

!        case 'R': return 1;
!        case 'K': return 1;
!        case 'D': return 2;
!        case 'E': return 2;
!        case 'H': return 3;
!        case 'F': return 3;
!        case 'W': return 3;
!        case 'Y': return 3;
!        case 'N': return 4;
!        case 'Q': return 4;
!        case 'S': return 4;
!        case 'T': return 4;
!        case 'A': return 5;
!        case 'I': return 5;
!        case 'L': return 5;
!        case 'M': return 5;
!        case 'V': return 5;
!        case 'C': return 5;
!        case 'G': return 6;
!        case 'P': return 6;

      return
!========================================================================================================
      end






