module polynomial_
use constants
use SpecialFunctionLib
implicit none
    
    private
    public:: polynomial
    !some related polynomials and function
    public:: Binomialcoef
    public:: LegendrePolynomials
    public:: norm_LegendrePolynomials
    public:: zeroPolynomial
    
    !-----------------------------------------
    type:: polynomial
    
        private
        real(rp),allocatable,dimension(:):: coefs_
        
    contains
    
        !--
        generic::           init    => init_degree,init_ar,init_ply
        procedure,private:: init_degree
        procedure,private:: init_ar
        procedure,private:: init_ply
        !--
        procedure::         degree
        procedure::         scoef
        procedure::         coefadd
        procedure::         contract
        procedure::         funcval
        procedure::         integral
        !--
        generic::           coef => coef_i,coefs_ptr
        procedure,private:: coef_i
        procedure,private:: coefs_ptr
        !--
        generic::           assignment(=)   => paEq
        generic::           operator(+)     => psPlus,spPlus
        generic::           operator(*)     => ppMultiply,spmultiply,psMultiply
        generic::           operator(/)     => psDivide
        generic::           operator(==)    => ppjdEq
        !a strange override
        !https: //software.intel.com/en-us/forums/intel-visual-fortran-compiler-for-windows/topic/713637
        procedure,pass(lhs),private::   paEq
        procedure,pass(lhs),private::   psPlus
        procedure,pass(rhs),private::   spPlus
        procedure,pass(lhs),private::   ppMultiply
        procedure,pass(lhs),private::   psMultiply
        procedure,pass(rhs),private::   spMultiply
        procedure,pass(lhs),private::   psDivide
        procedure,pass(lhs),private::   ppjdEq

    end type polynomial

    !------------------------------------------------
    interface Binomialcoef
        procedure::  Binomialcoef_int
        procedure::  Binomialcoef_general
    end interface Binomialcoef
    !------------------------------------------------
    
!-----------------------------------------
contains
    !--
    elemental subroutine init_degree(this,n)
    class(polynomial),intent(out)::         this
    integer(ip),intent(in)::                n
        allocate(this%coefs_(0:n))
        this%coefs_  = zero
    end subroutine init_degree
    !--
    pure subroutine init_ar(this,ar)
    class(polynomial),intent(out)::         this
    real(rp),dimension(0:),intent(in)::     ar
        allocate(this%coefs_,source = ar)
    end subroutine init_ar
    !--
    elemental subroutine init_ply(this,that)
    class(polynomial),intent(out)::     this
    class(polynomial),intent(in)::      that
        allocate(this%coefs_,source = that%coefs_)
    end subroutine init_ply

    !---
    elemental integer(ip) function degree(this)
    class(polynomial),intent(in)::      this
    type(polynomial)::                  cthis
        cthis = this%contract()
        degree = ubound(cthis%coefs_,dim=1)
    end function degree
    !---
    elemental real(rp) function coef_i(this,i)
    class(polynomial),intent(in)::  this
    integer(ip),intent(in)::        i
        coef_i = this%coefs_(i)
    end function coef_i
    !---
    function coefs_ptr(this)
    class(polynomial),target,intent(in)::this
    real(rp),dimension(:),pointer::     coefs_ptr
        coefs_ptr => this%coefs_
    end function coefs_ptr
    !---
    elemental subroutine scoef(this,i,coef)
    class(polynomial),intent(inout)::  this
    integer(ip),intent(in)::           i
    real(rp),intent(in)::              coef
        this%coefs_(i) = coef
    end subroutine scoef
    !--
    elemental subroutine coefadd(this,i,v)
    class(polynomial),intent(inout)::   this
    integer(ip),intent(in)::            i
    real(rp),intent(in)::               v
        this%coefs_(i) = this%coefs_(i) + v
    end subroutine coefadd
    !--
    elemental type(polynomial) function contract(this) result(cp)
    class(polynomial),intent(in)::      this
    integer(ip)::                       i,n
        n = ubound(this%coefs_,dim=1)
        do i=n,1,-1
            if(this%coefs_(i)==zero) then
                n = n - 1
            else
                exit
            endif
        enddo
        allocate(cp%coefs_(0:n),source=this%coefs_(0:n))
    end function contract
    !--
    pure real(rp) function funcval(this,x) result(y)
    class(polynomial),intent(in)::  this
    real(rp),intent(in)::           x
    integer(ip)::                   i
        y = zero
        do i=0,this%degree()
            y = y + this%coef(i) * x**i
        enddo
    end function funcval
    !--
    pure real(rp) function integral(this,lo,up)
    class(polynomial),intent(in)::  this
    real(rp),intent(in)::           lo,up
    real(rp)::                      ui,li,coef
    integer(ip)::                   i
        ui = zero; li = zero
        do i=0,this%degree()
            coef = this%coef(i) / dfloat(i+1)
            ui = ui + up**(i+1) * coef
            li = li + lo**(i+1) * coef
        enddo
        integral = ui - li  !less minus better
    end function integral    
    
    
    
!--------operator
    pure subroutine paEq(lhs,rhs)
    class(polynomial),intent(out)::     lhs
    real(rp),dimension(0:),intent(in):: rhs
        allocate(lhs%coefs_,source=rhs)
    end subroutine paEq
    !--
    elemental type(polynomial) function psPlus(lhs,rhs) result(p)
    class(polynomial),intent(in)::      lhs
    real(rp),intent(in)::               rhs
        allocate(p%coefs_ , source = lhs%coefs_)
        p%coefs_(0) = p%coefs_(0) + rhs
    end function psPlus
    !--
    elemental type(polynomial) function spPlus(lhs,rhs) result(p)
    real(rp),intent(in)::               lhs
    class(polynomial),intent(in)::      rhs
        p = rhs + lhs
    end function spPlus
    !--
    elemental type(polynomial) function ppMultiply(lhs,rhs) result(p)
    class(polynomial),intent(in)::      lhs
    type(polynomial),intent(in)::       rhs
    integer(ip)::                       i,j,ld,rd
        ld = lhs%degree();  rd =rhs%degree()
        call p%init(ld+rd)
        do j=0,ld
            do i=0,rd
                p%coefs_(i+j) = p%coefs_(i+j) + lhs%coefs_(j)*rhs%coefs_(i)
            enddo
        enddo
    end function ppMultiply
    !--
    elemental type(polynomial) function psMultiply(lhs,rhs) result(p)
    class(polynomial),intent(in)::      lhs
    real(rp),intent(in)::               rhs
        if(rhs/=zero) then
            allocate(p%coefs_,source=lhs%coefs_)
            p%coefs_ = rhs * p%coefs_
        else
            p = zeroPolynomial()
        endif
    end function psMultiply
    !--
    elemental type(polynomial) function spMultiply(lhs,rhs) result(p)
    real(rp),intent(in)::               lhs
    class(polynomial),intent(in)::      rhs
        p = rhs * lhs
    end function spMultiply
    !--
    elemental type(polynomial) function psDivide(lhs,rhs) result(p)
    class(polynomial),intent(in)::      lhs
    real(rp),intent(in)::               rhs
        allocate(p%coefs_,source=lhs%coefs_)
        p%coefs_ = p%coefs_ / rhs
    end function psDivide
    !--
    elemental logical(lp) function ppjdeq(lhs,rhs) result(l)
    class(polynomial),intent(in)::  lhs,rhs
    integer(ip)::                   n,i
        l = .true.
        n = lhs%degree()
        if(n==rhs%degree()) then
            do i=0,n
                if(lhs%coef(i)==rhs%coef(i)) cycle
                l = .false.; exit
            enddo
        else
            l = .false.
        endif
    end function ppjdeq
    
    
    !refer to wiki
    !----------------------
    pure integer(ip) function Binomialcoef_int(n,k) result(coef)
    integer(ip),intent(in)::    n,k
        coef = factorial(n-k+1,n) / factorial(k)
    end function Binomialcoef_int
    !----------------------
    pure real(rp) function Binomialcoef_general(a,k) result(coef)
    real(rp),intent(in)::       a
    integer(ip),intent(in)::    k
    integer(ip)::               i
    real(rp)::                  up
        up = 1.d0
        do i =1,k
            up = up*(a-i+1)
        enddo
        coef = up / dfloat( factorial(k) )
    end function Binomialcoef_general
    !---------------------
    elemental type(polynomial) function zeroPolynomial() result(z)
        allocate(z%coefs_(0:0)); z%coefs_ = zero
    end function zeroPolynomial
    !---------------------
    elemental function LegendrePolynomials(n) result(ply)
    integer(ip),intent(in)::                n
    type(polynomial)::                      ply
    integer(ip)::                           k
        call ply%init(n)
        do k=0,n
            ply%coefs_(k) = 2**n * Binomialcoef(n,k) * Binomialcoef(dfloat(n+k-1)/2.d0,n)
        enddo
    end function LegendrePolynomials
    !--------------------
    elemental function norm_LegendrePolynomials(n) result(ply)
    integer(ip),intent(in)::                n
    type(polynomial)::                      ply
        ply = sqrt(dfloat(2*n+1)/2.d0) * LegendrePolynomials(n)
    end function norm_LegendrePolynomials
    
end module polynomial_