module fixed_source

  use constants,  only: ZERO
  use global
  use output,     only: write_message, header
  use physics,    only: transport
  use random_lcg, only: set_particle_seed
  use source,     only: initialize_particle, sample_external_source, &
                        copy_source_attributes
  use string,     only: to_str
  use tally,      only: synchronize_tallies
  use timing,     only: timer_start, timer_stop

  type(Bank), pointer :: source_site => null()

contains

  subroutine run_fixedsource()

    integer(8) :: i ! index over histories in single cycle

    if (master) call header("FIXED SOURCE TRANSPORT SIMULATION", level=1)

    ! Allocate particle and dummy source site
    allocate(p)
    allocate(source_site)

    ! Turn timer and tallier on
    tallies_on = .true.
    call timer_start(time_active)

    ! ==========================================================================
    ! LOOP OVER BATCHES
    BATCH_LOOP: do current_batch = 1, n_batches

       call initialize_batch()

       ! Start timer for transport
       call timer_start(time_transport)

       ! =======================================================================
       ! LOOP OVER PARTICLES
       PARTICLE_LOOP: do i = 1, work

          ! Set unique particle ID
          p % id = (current_batch - 1)*n_particles + bank_first + i - 1

          ! set particle trace
          trace = .false.
          if (current_batch == trace_batch .and. current_gen == trace_gen .and. &
               bank_first + i - 1 == trace_particle) trace = .true.

          ! set random number seed
          call set_particle_seed(p % id)
          
          ! grab source particle from bank
          call sample_source_particle()

          ! transport particle
          call transport()

       end do PARTICLE_LOOP

       ! Accumulate time for transport
       call timer_stop(time_transport)

       call timer_start(time_ic_tallies)
       call synchronize_tallies()
       call timer_stop(time_ic_tallies)

    end do BATCH_LOOP

    call timer_stop(time_active)

    ! ==========================================================================
    ! END OF RUN WRAPUP

    if (master) call header("SIMULATION FINISHED", level=1)

  end subroutine run_fixedsource

!===============================================================================
! INITIALIZE_BATCH
!===============================================================================

  subroutine initialize_batch()

       message = "Simulating batch " // trim(to_str(current_batch)) // "..."
       call write_message(1)

       ! Reset total starting particle weight used for normalizing tallies
       total_weight = ZERO

  end subroutine initialize_batch

!===============================================================================
! SAMPLE_SOURCE_PARTICLE
!===============================================================================

  subroutine sample_source_particle()

    ! Set particle
    call initialize_particle()

    ! Sample the external source distribution
    call sample_external_source(source_site)

    ! Copy source attributes to the particle
    call copy_source_attributes(source_site)

  end subroutine sample_source_particle

end module fixed_source