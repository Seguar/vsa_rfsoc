function [weights] = nonconvex_rab(R, src_angle, numelements, eps)
    % Robust adaptive beamforming using worst-case performance 
    % optimization: a solution to the signal mismatch problem
    % https://ieeexplore.ieee.org/document/1166614/authors#authors
    %% 
    a = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(src_angle)));
    a_hat = [real(a)',imag(a)']';
    a_hat_m = [imag(a)', -real(a)']';
    w = optimvar('w',numelements*2,1);
    tau = optimvar('tau');
    u = chol(R);
    u_hat = [[real(u), -imag(u)];[imag(u), real(u)]];
    prob = optimproblem;
    prob.Objective = tau;
    prob.Constraints.cons1 = norm(u_hat*w) <= tau;
    prob.Constraints.cons2 = eps*norm(w) <= w'*a_hat-1;
    prob.Constraints.cons3 = w'*a_hat_m == 0;
%     x0.w = randn([numelements*2,1], "like", 1+1i);
    x0.w = randn([numelements*2,1]);
    x0.tau = rand([1,1]);
    sol = solve(prob, x0);
    weights = sol.w(1:numelements) + 1j*sol.w(numelements+1:numelements*2);  
%     sol.w
%     sol.tau
end