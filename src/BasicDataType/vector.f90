!-----------------------
!vector is a wrapper of fortran array, added some binding procedure
!vector inheriate all of the intrinsic operator of fortran array

!some tips about the array operator and assigment
!vc1.op.vc2, the output is the array | size = size(vc1), lboud = 1
!vc1.op.vc2, vc1>vc2, the output is dangerous!
!vc1 = vc2: when size(vc1)=size(vc2), just copy contents and doesn't change the bound of vc1
!vc1 = vc2: when size(vc1)/=size(vc2), let vc1 eq vc2 compeletely including bound
!vc1(:) = vc2(:): dim2<dim1 debug -> erro, release -> vc1 becomes dangerours
!vc1(:) = vc2(:): while dim2>=dim1, this is ok
    
!here i retain intrinsic type assigment for vector class and override the operator
!type binding operator would breaks the completeness between the parent and son types, 
!so the module interface is used to override the appropriate operator
!----------------------------------------------------------------
module vector_
use constants
implicit none

    private
    public:: vector,vector2d,vector3d
    public:: operator(+),operator(-),operator(*),operator(/),operator(**)
    public:: operator(.cross.),operator(.inner.),operator(.outer.),operator(.dot.)
    public:: assignment(=)
    
    
    type::  vector
    
        private
        
        real(rp),allocatable,dimension(:):: vc
        
    contains
    
        !--sp init
        procedure::         init_movealloc
        
        !--generic init
        generic::           init    => init_dim,    &
                                        init_ds,    &
                                        init_vals,  &
                                        init_vector
        procedure,private:: init_dim
        procedure,private:: init_ds
        procedure,private:: init_vals
        procedure,private:: init_vector
        
        
        !menber function
        generic::           ptr     => ptr_0,ptr_section
        procedure,private:: ptr_0
        procedure,private:: ptr_section
        !--
        generic::           val    => val_i,val_0,val_section
        procedure,private:: val_i
        procedure,private:: val_0
        procedure,private:: val_section
        !--
        procedure::         dim
        !--
        
        !--
        generic::           sval    => sval_val,        &
                                    sval_sectionval,    &
                                    sval_subvector,     &
                                    sval_sectionvals,   &
                                    sval_vals
        procedure,private:: sval_val
        procedure,private:: sval_sectionval
        procedure,private:: sval_subvector
        procedure,private:: sval_sectionvals
        procedure,private:: sval_vals
        
        !operation
        procedure::         mag
        procedure::         magSqr
        procedure::         initRight
        procedure::         prints
        
        !temporary variable use (=)
        !resident variable use (=) input sure with the same size
        !resident variable with different size of input use (copy)
        generic::           copy    => copy_v
        procedure,private:: copy_v
        !---------------------------------------------------------
        generic::           add     => add_v,add_val
        procedure,private:: add_v
        procedure,private:: add_val
        !--
        generic::           times   => times_v,times_val
        procedure,private:: times_v
        procedure,private:: times_val
        
    end type vector

    
!----a specified vector
    type,extends(vector)::  vector2d
    contains
        !sp init
        procedure::         init_movealloc   =>      init_movealloc_2d
        !generic init
        generic::           init        =>      init_null   !,init_scalvals
        procedure,private:: init_null   =>      init_null_2d
        procedure,private:: init_dim    =>      init_dim_2d
        procedure,private:: init_ds     =>      init_ds_2d
        procedure,private:: init_vals   =>      init_vals_2d
        procedure,private:: init_vector =>      init_vector_2d
        
        !lead to init conflict of init_dim/init_dim_2d, 
        !procedure,private:: init_scalar =>      init_scalar_2d
        
        !menber function
        procedure::         x
        procedure::         y
    end type vector2d
    
!----a specified vector
    type,extends(vector2d)::  vector3d
    contains
        !change the init_null, change the other inits
        procedure,private:: init_null   =>      init_null_3d
        
        !menber function
        procedure::         z
    end type vector3d

    
    
!---------------------------------------------
    interface operator(+)
        procedure::     vplus
        procedure::     vsplus
        procedure::     svplus
        procedure::     v2plus
        procedure::     v3plus
    end interface
    
    interface operator(-)
        procedure::     vminus
        procedure::     v2minus
        procedure::     v3minus
        procedure::     negv
        procedure::     negv2
        procedure::     negv3
    end interface
    
    interface operator(*)
        procedure::     vproduct
        procedure::     svproduct
        procedure::     sv2product
        procedure::     sv3product
        procedure::     vsproduct
        procedure::     v2sproduct
        procedure::     v3sproduct
    end interface
    
    interface operator(/)
        procedure::     vdivide
        procedure::     vsdivide
        procedure::     svdivide
        procedure::     v2sdivide
        procedure::     v3sdivide
    end interface
    
    interface operator(**)
        procedure::     vi2pow
        procedure::     vi4pow
        procedure::     vi8pow
    end interface
    
    interface operator(.cross.)
        procedure::     v2cross
        procedure::     v3cross
    end interface
    
    interface operator(.inner.) !inner product is usually called dot_product
        procedure::     vdot
    end interface
    
    interface operator(.outer.)
        procedure::     vouter
    end interface
    
    interface operator(.dot.)
        procedure::     vdot
    end interface
    
    !------------------------------
    interface assignment(=)
        procedure::     veqvals
        procedure::     veqvals2    !sp for v2d&v3d
        procedure::     veqscalvals
    end interface
    
!-----
contains

!-----vector
    !--
    pure subroutine init_movealloc(this,vals)
    class(vector),intent(out)::     this
    real(rp),dimension(:),allocatable,intent(inout):: vals
        call move_alloc(vals,this%vc)
    end subroutine init_movealloc
    
    !&&
    elemental subroutine init_dim(this,n)
    class(vector),intent(out)::         this
    integer(ip),intent(in)::            n
        allocate(this%vc(n))
        this%vc = zero
    end subroutine init_dim
    
    elemental subroutine init_ds(this,n,s)
    class(vector),intent(out)::         this
    integer(ip),intent(in)::            n
    real(rp),intent(in)::               s
        allocate(this%vc(n))
        this%vc = s
    end subroutine init_ds
    
    !&&
    pure subroutine init_vals(this,vals)
    class(vector),intent(out)::         this
    real(rp),dimension(:),intent(in)::  vals
        allocate(this%vc,source=vals)
    end subroutine init_vals
    
    !&&
    pure subroutine init_vector(this,v)
    class(vector),intent(out)::         this
    class(vector),intent(in)::          v
        allocate(this%vc,source=v%vc)
    end subroutine init_vector
    
    !&&
    elemental real(rp) function val_i(this,i)
    class(vector),intent(in)::          this
    integer(ip),intent(in)::            i
        val_i =   this%vc(i)
    end function val_i
    
    !&&
    elemental subroutine sval_val(this,index,val)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            index
    real(rp),intent(in)::               val
        this%vc(index) = val
    end subroutine sval_val
    
    elemental subroutine sval_sectionval(this,s,e,val)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            s,e
    real(rp),intent(in)::               val
        this%vc(s:e) = val
    end subroutine sval_sectionval
    
    elemental subroutine sval_subvector(this,s,e,v)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            s,e
    type(vector),intent(in)::           v
        this%vc(s:e) = v%vc
    end subroutine sval_subvector
    
    pure subroutine sval_sectionvals(this,s,e,vals)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            s,e
    real(rp),dimension(:),intent(in)::  vals
        this%vc(s:e) = vals
    end subroutine sval_sectionvals
    
    pure subroutine sval_vals(this,vals)
    class(vector),intent(inout)::       this
    real(rp),dimension(:),intent(in)::  vals
        this%vc(:) = vals
    end subroutine sval_vals
    
    
    !&&
    function ptr_0(this) result(vc)
    class(vector),target,intent(in)::   this
    real(rp),pointer,dimension(:)::     vc
        vc  =>  this%vc
    end function ptr_0
    
    !&&
    function ptr_section(this,s,e) result(vc)
    class(vector),target,intent(in)::   this
    integer(ip),intent(in)::            s,e
    real(rp),pointer,dimension(:)::     vc
        vc  =>  this%vc(s:e)
    end function ptr_section
    
    !&&
    pure function val_0(this) result(vc)
    class(vector),intent(in)::          this
    real(rp),allocatable,dimension(:):: vc
        allocate(vc,source = this%vc)
    end function val_0
    
    !&&
    pure function val_section(this,s,e) result(vc)
    class(vector),intent(in)::          this
    integer(ip),intent(in)::            s,e
    real(rp),allocatable,dimension(:):: vc
        allocate(vc,source = this%vc(s:e))
    end function val_section
    
    !&&
    elemental function dim(this)
    class(vector),intent(in)::          this
    integer(ip)::                       dim
        dim =   size( this%vc )
    end function Dim
    !&&
    elemental subroutine copy_v(this,v)
    class(vector),intent(inout)::       this
    type(vector),intent(in)::           v
    integer(ip)::                       mindim
        mindim = min(this%dim(),v%dim())
        this%vc(1:mindim) = v%vc(1:mindim)
    end subroutine copy_v
    !&&
    elemental subroutine add_v(this,v)
    class(vector),intent(inout)::       this
    type(vector),intent(in)::           v
    integer(ip)::                       dim
        dim = min(this%dim(),v%dim())
        this%vc(1:dim) = this%vc(1:dim) + v%vc(1:dim)
    end subroutine add_v
    
    !&&
    elemental subroutine add_val(this,i,v)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            i
    real(rp),intent(in)::               v
        this%vc(i) = this%vc(i) + v
    end subroutine add_val
    
    !&&
    elemental subroutine times_v(this,v)
    class(vector),intent(inout)::       this
    real(rp),intent(in)::               v
        this%vc = this%vc * v
    end subroutine times_v
    
    !&&
    elemental subroutine times_val(this,i,v)
    class(vector),intent(inout)::       this
    integer(ip),intent(in)::            i
    real(rp),intent(in)::               v
        this%vc(i) = this%vc(i) * v
    end subroutine times_val
    
    !&&
    elemental function mag(this)
    class(vector),intent(in)::          this
    real(rp)::                          mag
        mag = sqrt( this%magSqr() )
    end function mag
    
    !&&
    elemental function magSqr(this)
    class(vector),intent(in)::          this
    real(rp)::                          magSqr
        magSqr = this .dot. this
    end function magSqr
    
    !&&
    elemental function initRight(this) result(l)
    class(vector),intent(in)::          this
    logical(lp)::                       l
         l = merge( .true. , .false. , allocated(this%vc))
    end function initRight

    subroutine prints(this)
    class(vector),intent(in)::          this
        print*, 'vcprint Starts'
        print*, 'vcSize:',size(this%vc)
        print*, this%vc
        print*, 'vcprint Ends'
    end subroutine prints

    
    
!--------------------------------------    
!vector2d override part 
!-------------------------------------
    !--
    pure subroutine init_movealloc_2d(this,vals)
    class(vector2d),intent(out)::   this
    real(rp),dimension(:),allocatable,intent(inout):: vals
        call this%init()
        this%vc(:) = vals
    end subroutine init_movealloc_2d
    
    !&&
    elemental subroutine init_null_2d(this)
    class(vector2d),intent(out)::       this
        allocate(this%vc(2))
        this%vc = zero
    end subroutine init_null_2d
    
    elemental subroutine init_ds_2d(this,n,s)
    class(vector2d),intent(out)::       this
    integer(ip),intent(in)::            n
    real(rp),intent(in)::               s
        call this%init()
        this%vc = s
    end subroutine init_ds_2d
    
    !&& leading error
    elemental subroutine init_scalvals_2d(this,s)
    class(vector2d),intent(out)::       this
    real(rp),intent(in)::               s
        call this%init()
        this%vc = s
    end subroutine init_scalvals_2d
    
    !&&
    elemental subroutine init_dim_2d(this,n)
    class(vector2d),intent(out)::       this
    integer(ip),intent(in)::            n
        call this%init()
    end subroutine init_dim_2d
    
    !&&
    pure subroutine init_vals_2d(this,vals)
    class(vector2d),intent(out)::       this
    real(rp),dimension(:),intent(in)::  vals
        call this%init()
        this%vc(:) = vals
    end subroutine init_vals_2d
    
    !&&
    pure subroutine init_vector_2d(this,v)
    class(vector2d),intent(out)::       this
    class(vector),intent(in)::          v
        call this%init(v%vc)
    end subroutine init_vector_2d
    
    !&&
    elemental function x(this)
    class(vector2d),intent(in)::        this
    real(rp)::                          x
        x = this%vc(1)
    end function x
    
    !&&
    elemental function y(this)
    class(vector2d),intent(in)::        this
    real(rp)::                          y
        y = this%vc(2)
    end function y
    
    
!--------------------------------------    
!vector3d override part 
!-------------------------------------
    !&&
    elemental subroutine init_null_3d(this)
    class(vector3d),intent(out)::       this
        allocate(this%vc(3))
        this%vc = zero
    end subroutine init_null_3d

    !&&
    elemental function z(this)
    class(vector3d),intent(in)::        this
    real(rp)::                          z
        z = this%vc(3)
    end function z
      

    
    
    

    
!--------------------------------------    
!operator override
!-------------------------------------
    elemental type(vector) function vplus(lhs,rhs) result(vvp)
    type(vector),intent(in)::   lhs,rhs
        vvp%vc = lhs%vc + rhs%vc
    end function vplus
    
    elemental type(vector) function vsplus(lhs,rhs) result(vsp)
    type(vector),intent(in)::   lhs
    real(rp),intent(in)::       rhs
        vsp%vc = lhs%vc + rhs
    end function vsplus
    
    elemental type(vector) function svplus(lhs,rhs) result(svp)
    type(vector),intent(in)::   rhs
    real(rp),intent(in)::       lhs
        svp%vc = rhs%vc + lhs
    end function svplus
    
    
    !--
    elemental function v2plus(lhs,rhs) result(vvp)
    type(vector2d),intent(in):: lhs,rhs
    type(vector2d)::            vvp
        vvp%vc = lhs%vc+rhs%vc
    end function v2plus
    !--
    elemental function v3plus(lhs,rhs) result(vvp)
    type(vector3d),intent(in):: lhs,rhs
    type(vector3d)::            vvp
        vvp%vc = lhs%vc+rhs%vc
    end function v3plus
    !--
    !if dim of lhs less than rhs, it leads to error
    elemental function vminus(lhs,rhs) result(vvm)
    type(vector),intent(in)::   lhs,rhs
    type(vector)::              vvm
        vvm%vc  =   lhs%vc - rhs%vc 
    end function vminus
    !--
    !if dim of lhs less than rhs, it leads to error
    elemental function v2minus(lhs,rhs) result(vvm)
    type(vector2d),intent(in):: lhs,rhs
    type(vector2d)::            vvm
        vvm%vc  =   lhs%vc - rhs%vc 
    end function v2minus
    !--
    !if dim of lhs less than rhs, it leads to error
    elemental function v3minus(lhs,rhs) result(vvm)
    type(vector3d),intent(in):: lhs,rhs
    type(vector3d)::            vvm
        vvm%vc  =   lhs%vc - rhs%vc 
    end function v3minus
    !--
    elemental function negv(rhs) result(v)
    type(vector),intent(in)::   rhs
    type(vector)::              v
        v%vc = -rhs%vc
    end function negv
    !--
    elemental function negv2(rhs) result(v)
    type(vector2d),intent(in):: rhs
    type(vector2d)::            v
        v%vc = -rhs%vc
    end function negv2
    !--
    elemental function negv3(rhs) result(v)
    type(vector3d),intent(in):: rhs
    type(vector3d)::            v
        v%vc = -rhs%vc
    end function negv3
    
    !--
    elemental function vdot(lhs,rhs) result(vvd)
    class(vector),intent(in)::  lhs,rhs
    real(rp)::                  vvd
        vvd =  sum(lhs%vc * rhs%vc)
    end function vdot
    
    !--
    pure function vouter(lhs,rhs) result(ts)
    class(vector),intent(in)::          lhs,rhs
    real(rp),dimension(:,:),allocatable::ts
    integer(ip)::                       i,j
        allocate( ts( lhs%dim(), rhs%dim() ) )
        do j=1,rhs%dim()
            do i=1,lhs%dim()
                ts(i,j) = lhs%vc(i) * rhs%vc(j)
            enddo
        enddo
    end function vouter
    
    !--
    elemental function v2cross(lhs,rhs) result(vvcr)
    type(vector2d),intent(in)::         lhs
    type(vector2d),intent(in)::         rhs
    real(rp)::                          vvcr
        vvcr = lhs%vc(1) * rhs%vc(2) - lhs%vc(2)*rhs%vc(1)
    end function v2cross
    
    !--
    elemental function v3cross(lhs,rhs) result(vvcr)
    type(vector3d),intent(in)::         lhs
    type(vector3d),intent(in)::         rhs
    type(vector3d)::                    vvcr
        call vvcr%init()
        vvcr%vc(1)  =   lhs%vc(2) * rhs%vc(3)   -   lhs%vc(3) * rhs%vc(2)
        vvcr%vc(2)  =   lhs%vc(3) * rhs%vc(1)   -   lhs%vc(1) * rhs%vc(3)
        vvcr%vc(3)  =   lhs%vc(1) * rhs%vc(2)   -   lhs%vc(2) * rhs%vc(1)
    end function v3cross
    
    !--
    elemental type(vector) function vproduct(lhs,rhs) result(vr)
    type(vector),intent(in)::           lhs,rhs
        vr%vc = lhs%vc * rhs%vc
    end function vproduct
    
    !--
    elemental function svproduct(lhs,rhs) result(vr)
    real(rp),intent(in)::               lhs
    type(vector),intent(in)::           rhs
    type(vector)::                      vr
        vr%vc = lhs * rhs%vc
    end function svproduct
    
    !--
    elemental function sv2product(lhs,rhs) result(vr)
    real(rp),intent(in)::               lhs
    type(vector2d),intent(in)::         rhs
    type(vector2d)::                    vr
        vr%vc = lhs * rhs%vc
    end function sv2product
    
    !--
    elemental function sv3product(lhs,rhs) result(vr)
    real(rp),intent(in)::               lhs
    type(vector3d),intent(in)::         rhs
    type(vector3d)::                    vr
        vr%vc = lhs * rhs%vc
    end function sv3product
    
    !--
    elemental function vsproduct(lhs,rhs) result(vr)
    type(vector),intent(in)::           lhs
    real(rp),intent(in)::               rhs
    type(vector)::                      vr
        vr%vc = rhs * lhs%vc
    end function vsproduct
    
    !--
    elemental function v2sproduct(lhs,rhs) result(vr)
    type(vector2d),intent(in)::         lhs
    real(rp),intent(in)::               rhs
    type(vector2d)::                    vr
        vr%vc = rhs * lhs%vc
    end function v2sproduct
    
    !--
    elemental function v3sproduct(lhs,rhs) result(vr)
    type(vector3d),intent(in)::         lhs
    real(rp),intent(in)::               rhs
    type(vector3d)::                    vr
        vr%vc = rhs * lhs%vc
    end function v3sproduct
    
    !--
    elemental function vdivide(lhs,rhs) result(vr)
    type(vector),intent(in)::           lhs,rhs
    type(vector)::                      vr
        vr%vc = lhs%vc / rhs%vc
    end function vdivide
    
    
    !--
    elemental function vsdivide(lhs,rhs) result(vr)
    real(rp),intent(in)::               rhs
    type(vector),intent(in)::           lhs
    type(vector)::                      vr
        vr%vc = lhs%vc / rhs
    end function vsdivide
    
    !--
    elemental function svdivide(lhs,rhs) result(vr)
    real(rp),intent(in)::               lhs
    type(vector),intent(in)::           rhs
    type(vector)::                      vr
        vr%vc = lhs / rhs%vc
    end function svdivide
    
    !--
    elemental function v2sdivide(lhs,rhs) result(vr)
    real(rp),intent(in)::               rhs
    type(vector2d),intent(in)::         lhs
    type(vector2d)::                    vr
        vr%vc = lhs%vc / rhs
    end function v2sdivide
    
    !--
    elemental type(vector3d) function v3sdivide(lhs,rhs) result(vr)
    real(rp),intent(in)::               rhs
    type(vector3d),intent(in)::         lhs
        vr%vc = lhs%vc / rhs
    end function v3sdivide
    
    
    !-----------------------
    elemental type(vector) function vi4pow(lhs,rhs) result(v)
    type(vector),intent(in)::   lhs
    integer(4),intent(in)::     rhs
        v%vc = lhs%vc ** rhs
    end function vi4pow
    
    elemental type(vector) function vi2pow(lhs,rhs) result(v)
    type(vector),intent(in)::   lhs
    integer(2),intent(in)::     rhs
        v%vc = lhs%vc ** rhs
    end function vi2pow
    
    elemental type(vector) function vi8pow(lhs,rhs) result(v)
    type(vector),intent(in)::   lhs
    integer(8),intent(in)::     rhs
        v%vc = lhs%vc ** rhs
    end function vi8pow
    
!----------assignment
    !intrinsic type assignment| deallocate lhs and then copy bitbybit
    !--
    pure subroutine Veqvals(lhs,rhs)
    type(vector),intent(inout)::        lhs
    real(rp),dimension(:),intent(in)::  rhs
        lhs%vc = rhs
    end subroutine Veqvals
    !--
    elemental subroutine VeqScalvals(lhs,rhs)
    class(vector),intent(inout)::       lhs
    real(rp),intent(in)::               rhs
        lhs%vc = rhs
    end subroutine VeqScalvals
    !--
    pure subroutine Veqvals2(lhs,rhs)
    class(vector2d),intent(inout)::     lhs
    real(rp),dimension(:),intent(in)::  rhs
        lhs%vc(:) = rhs(:)
    end subroutine Veqvals2
    
end module vector_