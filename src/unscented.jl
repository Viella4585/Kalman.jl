include("unscentedtypes.jl")

# Predict and update functions

# Now a target for abstraction
function predict(kf::AdditiveUnscentedKalmanFilter)
    σp = map(kf.f.f,kf.σ)
    AdditiveUnscentedKalmanFilter(kf.x,kf.f,kf.z,σp,kf.α,kf.β,kf.κ,kf.wm,kf.wc)
end

function predict!(kf::AdditiveUnscentedKalmanFilter)
    σp = map(kf.f.f,kf.σ)
    kf.σ = σp
    kf
end

function estimate(kf::AdditiveUnscentedKalmanFilter)
    xhat = dot(kf.wm,kf.σ)
    phat = dot(kf.wc,
               map(x->(x-xhat)*(x-xhat)',kf.σ))+kf.f.q
    State(xhat,phat)
end

function estimate!(kf::AdditiveUnscentedKalmanFilter)
    xhat = dot(kf.wm,kf.σ)
    phat = dot(kf.wc,
               map(x->(x-xhat)*(x-xhat)',kf.σ))+kf.f.q
    kf.x = State(xhat,phat)
end

function update(kf::AdditiveUnscentedKalmanFilter,y::Observation)
    # Predicted mean
    xhat = dot(kf.wm,kf.σ)

    # Predicted covariance
    pu = map(x->(x-xhat)*(x-xhat)',kf.σ)
    phat = dot(kf.wc,pu) + kf.f.q 

    # Predicted observations
    yp = map(kf.z.h,kf.σ) # Run sigmas through h
    yhat = dot(kf.wm,yp) # Weight to find mean

    # Residuals in state and observation
    resx = map(x->x-xhat,kf.σ) # I think that's right
    resy = map(y->y-yhat,yp)

    # Covariances of state and observation
    pyy = dot(kf.wc,map(y->y*y',resy)) + r
    pxy = dot(kf.wc,map((x,y)->x*y',resx,resy))

    # Kalman gain
    k = pxy*inv(pyy)

    # Update state estimate
    xk = xhat + k*(y[i]-yhat)
    pk = phat - k*pyy*k'
    
    # Should recalculate sigmas from the new state
    AdditiveUnscentedKalmanFilter(State(xk,pk),kf.f,kf.z,kf.α,kf.β,kf.κ,kf.wm,kf.wc)
end

function update!(kf::AdditiveUnscentedKalmanFilter,y::Observation)
    # Predicted mean
    xhat = dot(kf.wm,kf.σ)

    # Predicted covariance
    pu = map(x->(x-xhat)*(x-xhat)',kf.σ)
    phat = dot(kf.wc,pu) + kf.f.q 

    # Predicted observations
    yp = map(kf.z.h,kf.σ) # Run sigmas through h
    yhat = dot(kf.wm,yp) # Weight to find mean

    # Residuals in state and observation
    resx = map(x->x-xhat,kf.σ) # I think that's right
    resy = map(y->y-yhat,yp)

    # Covariances of state and observation
    pyy = dot(kf.wc,map(y->y*y',resy)) + r
    pxy = dot(kf.wc,map((x,y)->x*y',resx,resy))

    # Kalman gain
    k = pxy*inv(pyy)

    # Update state estimate
    xk = xhat + k*(y[i]-yhat)
    pk = phat - k*pyy*k'
    
    kf.x = State(xk,pk)

    # Need to recalculate sigma points after update
    kf.σ = sigma(kf)

    kf # Return the mutated filter
end

function predictupdate!(kf::AdditiveUnscentedKalmanFilter,y::Observation)
    update!(predict!(kf),y)
end


