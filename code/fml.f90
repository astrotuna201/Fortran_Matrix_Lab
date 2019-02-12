PROGRAM fml

use fml_lib
use tm_module
use bg_module

implicit none

! local variables
integer::n,nn,t,p,count,save_count
real::start,finish,sum_val,start2,finish2
count=0
save_count=1
! initialise parameters and arrays
call initialise_model()
! allocate arrays, assign parameter values
call setup_model()
! load transport matrix data
call load_TM_data()


print*,'*************************'
print*,'Running model...'
! run simulation
call cpu_time(start)

do t=1,gen_runtime_years*tm_n_dt

	J(:,:)=0.0
	particles(:,:)=0.0
	export(:)=0.0
	call cpu_time(start2)
	if(mod(t,bg_dt_ratio)==0)THEN ! circulation + biogeochemistry step
	
		call tm_vars_at_dt() 
		
		if(bg_C_select)then
		call calc_C_consts()
		call calc_pCO2()
		end if
		
		call PO4_uptake()
		
		call POP_remin()
				
		call DOP_remin()
		
		call calc_gasexchange()
		
		call restore_atm_CO2()
		
		!call cpu_time(start2)
		tracers=amul(Aexp,tracers_1)
		call update_bgc()
		tracers=amul(Aimp,tracers)
		tracers_1=tracers
		!call cpu_time(finish2)
		
	else ! circulation only step
		call cpu_time(start2)
		tracers=amul(Aexp,tracers_1)
		tracers=amul(Aimp,tracers)
		tracers_1=tracers

		!call cpu_time(finish2)
		
 	end if
 	call cpu_time(finish2)
		
	call integrate_output(t,save_count)
	
	if(mod(t,tm_n_dt)==0.0)then
		call print_to_screen(t,finish2-start2)
	end if
		
	dt_count=dt_count+1
	
	! revert timestep counter to zero
	if(dt_count.gt.tm_n_dt)then
		dt_count=1
	end if
	
end do
call cpu_time(finish)
print*,'Time taken =',finish-start,'seconds'
print*,'*************************'
print*,

! write output to netcdf file
print*,'*************************'
!call write_output_netcdf()
call write_restart()
print*,'*************************'




END PROGRAM fml