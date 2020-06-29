using Pumas
using CSV, DataFrames
using LinearAlgebra
using Plots
using Query

tmdd = @model begin
    @param begin
        tvCl ∈ RealDomain(lower=0.0001, upper=10.0, init=1.0)
        tvV ∈ RealDomain(lower=0.0001, upper=100.0, init=1.0)
        tvkint ∈ RealDomain(lower=0.0001, upper=100.0, init=1.0)
        tvkon ∈ RealDomain(lower=0.0001, upper=100.0, init=1.0)
        tvR0 ∈ RealDomain(lower=0.0001, upper=100.0, init=1.0)
        Ω ∈ PDiagDomain(1)
        σ_prop ∈ RealDomain(lower=0.0001, init=0.3)
    end
    @random begin
        η ~ MvNormal(Ω)
    end

    @pre begin
        Cl = tvCl * exp(η[1])
        V = tvV
        kint = tvkint
        kon = tvkon
        R0 = tvR0
        bioav = 1/V
    end

    @init begin
        R = R0
    end

    @vars begin
        kel = Cl/V

        Rtot = R0                 # total receptor concentration (constant)
        Ltot = L + P
        R    = Rtot - P  # free receptor concentration

        IPRED_L = L                         # Free Drug Cocncentration (nM)
        IPRED_R = R
        IPRED_P = P

        #TO = R/Rtot
        TO = (1 - R/Rtot)*100
        RR = R/R0
    end

    @dynamics begin
        L'    = -kel*L - kon*L*(R0-P)
        P'    = kon*L*(R0-P) - kint*P
    end

    @derived begin
        dv ~ @.Normal(IPRED_L, sqrt(IPRED_L^2 * σ_prop))
    end
end

parameter = (
        tvCl   = 0.005,
        tvV    = 0.05,  # volume of central compartment (L/kg)
        tvkint = 0.2,
        tvkon = 0.5,
        tvR0   = 3.0,  # inital concentration of receptor  in central compartment (nM),
        Ω = Diagonal([0.0]),
        σ_prop = 0.025
        )

dose = 1
tlast = 100
e1 = DosageRegimen(dose)
pop1 = Population(map(i -> Subject(id=i,evs=e1),1:1))
#pop = Population(vcat(pop1,pop2,pop3))

using Random
Random.seed!(123456)
sim = simobs(tmdd, pop1, parameter, obstimes=0:1:tlast)
plot(sim, obsnames=[:IPRED_L])
plot(sim, obsnames=[:IPRED_L, :IPRED_R, :IPRED_P], layout=(1,3))
plot(sim, obsnames=[:IPRED_L, :IPRED_R, :TO, :RR], layout=(2,2))

parameter = (
        tvCl   = 0.005,
        tvV    = 0.05,  # volume of central compartment (L/kg)
        tvkint = 0.2,
        tvkon = 0.5,
        tvR0   = 3.0,  # inital concentration of receptor  in central compartment (nM),
        Ω = Diagonal([0.1]),
        σ_prop = 0.025
        )


pop2 = Population(map(i -> Subject(id=i,evs=e1),1:20))
Random.seed!(12345)
sim2 = simobs(tmdd, pop2, parameter, obstimes=0:1:tlast)
plot(sim2, obsnames=[:IPRED_L, :IPRED_R, :IPRED_P], layout=(1,3))
