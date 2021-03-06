program triplepolinom
implicit none
integer(4) nex
real(8),allocatable:: p(:),x(:),t(:),mm(:)
integer(4) i,ii,iii,iiii 	!variables for cycling
integer(4) k,m,r 		!k for pressure; m for temp; r for mol.mass
real(8),allocatable:: ft(:,:), fnt(:,:)
real(8),allocatable:: im(:,:),bm(:),iin(:,:)
real(8),allocatable:: a(:)
real(8),allocatable:: aopt(:)
real(8),allocatable:: acur(:)
integer(4) err
real(8) rmsav,xf
real(8),allocatable:: rms(:),func(:)
integer(4) norm
real(8) pmax,tmax,xmax,mmmax
character(10) tempstring
integer(4) debug
real(8),allocatable:: am(:,:)
integer(4) npar
integer(4) ki,mi
integer(4) kopt,mopt
real(8) rmsmin
real(8) avrmsopt,avrmscur
real(8) ftest1,ftest2
character(20) erfile
integer(4) reln
real(8) absdev,reldev,absdev2,reldev2
real(8) maxabs,maxrel

print *, 'calculating polnom coefficients'
open(7,file='input.in')
read(7,'(a)') tempstring
read(7,'(i5)') nex
read(7,'(a)') tempstring
read(7,'(i5)') k
read(7,'(a)') tempstring
read(7,'(i5)') m
read(7,'(a)') tempstring
read(7,'(i5)') r
norm=1
debug=0
allocate(p(nex))
allocate(x(nex))
allocate(t(nex))
allocate(mm(nex))
open(8,file='points.in')
do i=1,nex
	read(8,*) p(i), t(i),mm(i),x(i)
enddo
close(8)

pmax=-100000000.0
tmax=-100000000.0
xmax=-100000000.0
mmmax=-100000000.0
if (norm==1) then
	do i=1,nex
 		if (p(i)>pmax .and. p(i)>0.0) then
 			pmax=p(i)
 		endif
 		if (t(i)>tmax .and. t(i)>0.0) then
 			tmax=t(i)
 		endif
 		if (x(i)>xmax .and. x(i)>0.0) then
 			xmax=x(i)
 		endif
 		if (mm(i)>mmmax .and. mm(i)>0.0) then
 			mmmax=mm(i)
 		endif
 	enddo
 do i=1,nex
 	p(i)=p(i)/pmax
 	t(i)=t(i)/tmax
 	x(i)=x(i)/xmax
 	mm(i)=mm(i)/mmmax
 enddo
 else 
 	pmax=1.0
 	tmax=1.0
 	xmax=1.0
 	mmmax=1.0
 endif
print *,'Normalising constants ',pmax,tmax,mmmax,xmax

allocate(fnt(nex,(k+1)*(m+1)*(r+1)))
allocate(ft((k+1)*(m+1)*(r+1),nex))
allocate(im((k+1)*(m+1)*(r+1),(k+1)*(m+1)*(r+1)))
allocate(bm((k+1)*(m+1)*(r+1)))
allocate(a((k+1)*(m+1)*(r+1)))
allocate(iin((k+1)*(m+1)*(r+1),(k+1)*(m+1)*(r+1)))
allocate(acur((10+1)*(10+1)*(10+1)))
allocate(aopt(1000))
npar=0
do i=2,9
	do ii=2,9
		npar=npar+1
	enddo
enddo

allocate(am(npar,(k+1)*(m+1)))

!get Ф matrix

do i=1,k+1
	do ii=1,m+1
		do iiii=1,r+1
			do iii=1,nex
				!       ((m+1)*(r+1))*(i-1)+(ii-1)*(r+1)+iiii
				fnt(iii,((m+1)*(r+1))*(i-1)+(ii-1)*(r+1)+iiii)=t(iii)**(ii-1)*p(iii)&
				&**(i-1)*mm(iii)**(iiii-1)
			enddo
		enddo
	enddo
enddo

if (debug==1) then
	print *, 'Ф matrix write done'
	open(17,file='f.out')
	do i=1,nex
		do ii=1,(k+1)*(m+1)*(r+1)
			write(17,'(f30.10,a,$)') fnt(i,ii), ' '
		enddo
		write(17,'(a)') ' '
	enddo
	close(17)
endif

!get ФT matrix

do i=1,(k+1)*(m+1)*(r+1)
	do ii=1,nex
		ft(i,ii)=fnt(ii,i)
	enddo
enddo
if (debug==1) then
	print *,'Ф  invervion matrix done'

	open(17,file='ft.out')
	do i=1,(k+1)*(m+1)*(r+1)
		do ii=1,nex
			write(17,'(f30.10,a,$)') ft(i,ii), ' '
		enddo
		write(17,'(a)') ' '
	enddo
	close(17)
endif
! get I matrix

do i=1,(k+1)*(m+1)*(r+1)
	do ii=1,(k+1)*(m+1)*(r+1)
		im(i,ii)=0.0
		do iii=1,nex
			im(i,ii)=im(i,ii)+ft(i,iii)*fnt(iii,ii)
		enddo
	enddo
enddo
if (debug==1) then
	print *,'I matrix write done'
	open(17,file='i.out')
	do i=1,(k+1)*(m+1)*(r+1)
		do ii=1,(k+1)*(m+1)*(r+1)
			write(17,'(f30.10,a,$)') im(i,ii), ' '
		enddo
		write(17,'(a)') ' '
	enddo
	close(17)
endif

!get B matrix

do i=1,(k+1)*(m+1)*(r+1)
	bm(i)=0.0
	do iii=1,nex
		bm(i)=bm(i)+ft(i,iii)*x(iii)
	enddo
enddo

if (debug==1) then
	print *, 'B matrix done'
	open(17,file='b.out')
	do i=1,(k+1)*(m+1)*(r+1)
		write(17,'(f30.10,a)') bm(i), ' '
	enddo
	close(17)
endif

!get inversion of I matrix

do i=1,(k+1)*(m+1)*(r+1)
	do ii=1,(k+1)*(m+1)*(r+1)
		iin(i,ii)=im(i,ii)
	enddo
enddo

print *,'kmr', (k+1)*(m+1)*(r+1)
if (debug==1) then
	open(17,file='iinbefore.out')
	print *, 'Inversion matrix write done'
	do i=1,(k+1)*(m+1)*(r+1)
		do ii=1,(k+1)*(m+1)*(r+1)
			write(17,'(f30.10,a,$)') iin(i,ii), ' '
		enddo
		write(17,'(a)') ' '
	enddo
	close(17)
endif

call matr(iin,(k+1)*(m+1)*(r+1),(k+1)*(m+1)*(r+1),err)

if (debug==1) then
	open(17,file='iin.out')
	print *, 'Inversion matrix write done'
	do i=1,(k+1)*(m+1)*(r+1)
		do ii=1,(k+1)*(m+1)*(r+1)
			write(17,'(f30.10,a,$)') iin(i,ii), ' '
		enddo
		write(17,'(a)') ' '
	enddo
	close(17)
endif
print *, 'invers matrix ok'
do i=1,(k+1)*(m+1)*(r+1)
	a(i)=0.0
	do iii=1,(k+1)*(m+1)*(r+1)
		a(i)=a(i)+iin(i,iii)*bm(iii)
	enddo
enddo
rmsav=0.0

do i=1,k+1
	do ii=1,m+1
		do iii=1,r+1
			acur(((m+1)*(r+1))*(i-1)+(ii-1)*(r+1)+iii)=a(((m+1)*(r+1))*(i-1)+(ii-1)&
			&*(r+1)+iii)/tmax**(ii-1)/pmax**(i-1)*xmax/mmmax**(iii-1)
		enddo
	enddo
enddo
rmsav=0.0
absdev=0.0
absdev2=0.0
reldev=0.0
reldev2=0.0
reln=0
maxrel=9999999999999.9
maxabs=9999999999999.9
open(21,file='check.out')
write(21,'(13a)') 'P_val ',char(9),'T_val ',char(9),'x_val ',char(9),'y_val ',char(9),'y_calc',&
	&char(9), 'absolute_deviation ', char(9),'relative_deviation_%'
do i=1,nex
	call dpfunc(acur,k,m,r,p(i)*pmax,t(i)*tmax,mm(i)*mmmax,ftest1)
	write(21,'(6(e12.6,a),e12.6)') p(i)*pmax,char(9),t(i)*tmax,char(9),mm(i)*mmmax,char(9),x(i)*xmax,&
	&char(9),ftest1,char(9),x(i)*xmax-ftest1&
	&,char(9),(x(i)*xmax-ftest1)/(x(i)*xmax)*100.0
	rmsav=rmsav+(x(i)*xmax-ftest1)*(x(i)*xmax-ftest1)
	absdev=absdev+(x(i)*xmax-ftest1)
	absdev2=absdev2+abs((x(i)*xmax-ftest1))
	if(abs(x(i)*xmax-ftest1)<maxabs) then
		maxabs=abs(x(i)*xmax-ftest1)
	endif
	print *,absdev
	if (x(i)/=0.0) then
		if (abs(x(i)*xmax-ftest1)/(x(i)*xmax)<maxrel) then
			maxrel=abs(x(i)*xmax-ftest1)/(x(i)*xmax)
		endif
		reldev=reldev+(x(i)*xmax-ftest1)/(x(i)*xmax)
		reldev2=reldev2+abs(x(i)*xmax-ftest1)/(x(i)*xmax)
		reln=reln+1
	endif
enddo
rmsav=rmsav/float(nex)
absdev=absdev/float(nex)
reldev=reldev/float(reln)
close(21)

open(21,file='parameters.out')
write(21,'(a,e20.10)') 'average root mean square deviation ', sqrt(rmsav)
write(21,'(a,e20.10,a)') 'average relative deviation ', reldev *100.0 , '  %'
write(21,'(a,e20.10,a)') 'maximim relative deviation ', maxrel *100.0 , '  %'
write(21,'(a,e20.10)') 'average absolut deviation ', absdev
write(21,'(a,e20.10)') 'maximum absolut deviation ', maxabs
!print *, 'half ok'
do i=1,k+1
	do ii=1,m+1
		do iii=1,r+1
			print *,'a',(i-1),(ii-1),(iii-1),&
			& acur(((m+1)*(r+1))*(i-1)+(ii-1)*(r+1)+iii)
			write(21,'(a,i2,i2,i2,e20.10)') 'a',(i-1),(ii-1),(iii-1),&
			& acur(((m+1)*(r+1))*(i-1)+(ii-1)*(r+1)+iii)
		enddo
	enddo
enddo
close(21)



end program



subroutine matr(pw,n,nm,j1)
integer(4)  nm,n,j1,m,j,i,k,L
real(8) pw(nm,nm)
real(8) qw(500,500),jh(500)
real(8)  P,Q
	j1=1
	m=0
	do 100 j=1,n
 100    jh(j)=1
	do 110 i=1,n
	do 110 j=1,n
	qw(i,j)=0.
	if (i.eq.j) qw(i,j)=1.
 110    continue
 120    p=0.
	do 130 i=1,n
	do 130 j=1,n
	if((jh(i).lt.0).or.(jh(j).lt.0)) goto 130
	if(abs(pw(i,j)).le.p) goto 130
	p=abs(pw(i,j))
	k=i
	l=j
 130    continue
	if (m.eq.0) q=p
	if ((p/q).ge.1.e-20) goto 140
	j1=-1
	return
 140    m=m+1
	do 150 j=1,n
	if (j.ne.l) pw(k,j)=pw(k,j)/pw(k,l)
 150    qw(k,j)=qw(k,j)/pw(k,l)
	do 160 i=1,n
	do 160 j=1,n
	if(i.eq.k) goto 160
	if(j.ne.l) pw(i,j)=pw(i,j)-pw(i,l)*pw(k,j)
	qw(i,j)=qw(i,j)-pw(i,l)*qw(k,j)
 160    continue
	if(k.eq.l) goto 190
	do 170 j=1,n
	p=pw(l,j)
	pw(l,j)=pw(k,j)
 170    pw(k,j)=p
	do 180 j=1,n
	p=qw(l,j)
	qw(l,j)=qw(k,j)
 180    qw(k,j)=p
 190    jh(l)=-1
	if (m.lt.n) goto 120
	do 200 i=1,n
	do 200 j=1,n
 200    pw(i,j)=qw(i,j)
	return
	end


subroutine dpfunc(as,ks,ms,rs,ps,ts,mms,xs)
implicit none
real(8) ps,ts,xs,mms
integer(4) ks,ms,is,iis,iiis,rs
real(8) as((10+1)*(10+1)*(10+1))
xs=0.0
do is=1,(ks+1)
	do iis=1,(ms+1)
		do iiis=1,(rs+1)
			xs=xs+as((is-1)*(ms+1)*(rs+1)+(iis-1)*(rs+1)+iiis)*ts**&
			&(iis-1)*ps**(is-1)*mms**(iiis-1)
			!print *, as((is-1)*(ms+1)+iis),ts**(iis-1),ps**(is-1)
			!pause
		enddo
	enddo
enddo
end subroutine
