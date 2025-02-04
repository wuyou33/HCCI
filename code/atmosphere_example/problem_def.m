function dataG = problem_def()
global opt_dist
% opt_dist.save_dir = uigetdir();
opt_dist.FLAGS.compare_with_CI = 1;
opt_dist.nAgents = 9;
opt_dist.dt = 1;
opt_dist.dimAgents = 1;
opt_dist.obs.Range = 1.2;
opt_dist.dimState = 810;

opt_dist.obs.R = (0.05)^2;
opt_dist.dimObs =1;%opt_dist.dimAgents;
opt_dist.nIterations = 60;
opt_dist.nSteps = 30;
opt_dist.scenario = '2';
opt_dist.motion.Q = (0.01)^2;
% opt_dist.
NUM_SYS             = opt_dist.dimState;   %   DOF of system
L = 1;                      %   Length of the rod
alf = 4.2*1e-5;             %   thermal diffusivity
xlim = [0, L];
dx = (xlim(2) - xlim(1))/ (NUM_SYS-1); 
nNodes = opt_dist.dimState ;
% x_nodes = xlim(1) + [0 : nNodes-1] * dx;  % nodes 
% dt = 4;                         % time step
r = alf * opt_dist.dt/(dx^2);            % unstable if r > 0.5
% [A]=heat_system2(NUM_SYS ,r); 
% [A,x_nodes] = atmosphere();
% load('data_A_x0.mat')
[A,x0,B,C] = create_sys_atmosphere();

x_nodes = x0;

x_state =x_nodes;


%%

%%%% building the graph
full_Adj = ones(opt_dist.nAgents,opt_dist.nAgents);
topol_Adj = zeros(opt_dist.nAgents,opt_dist.nAgents);
for i=1:opt_dist.nAgents
    topol_Adj(i,max(1,i-3):min(opt_dist.nAgents,i+3)) =1;
end


% obs_Adj = [1 1 0 0;...
%     1 1 1 0;...
%     0 1 1 1;...
%     0 0 1 1];
obs_Adj = topol_Adj;%ones(opt_dist.nAgents,opt_dist.nAgents);
fault_Adj = zeros(opt_dist.nAgents,opt_dist.nAgents);
fault_Adj = obs_Adj;
disNode1 = randi([1 opt_dist.nAgents],1,1);                             

disNode2 = randi([1 opt_dist.nAgents],1,1);                             
disNode3 = randi([1 opt_dist.nAgents],1,1);                             
disNode4 = randi([1 opt_dist.nAgents],1,1);                             
mask = generate_mask(opt_dist.nAgents,disNode1).*generate_mask(opt_dist.nAgents,disNode2)...
     .*generate_mask(opt_dist.nAgents,disNode3).*generate_mask(opt_dist.nAgents,disNode4);

% for idx_fault=10:13
% fault_Adj(idx_fault,:) = zeros(1,opt_dist.nAgents);
% fault_Adj(idx_fault,idx_fault)=1;
% end

fault_Adj = mask.*obs_Adj;
% for i=1:opt_dist.nAgents
%     for j=1:opt_dist.nAgents
%         
%         if topol_Adj(i,j)==1
%             if rand<=0.6
%                 fault_Adj(i,j) = 1;
%             end
%         end
%     end
% end


opt_dist.A = A;
G_full = generate_graph(full_Adj);
G = generate_graph(topol_Adj);
G_fault = generate_graph(fault_Adj);
G_obs = generate_graph(obs_Adj);

opt_dist.Graphs.G_obs = G_obs;

opt_dist.Graphs.G_full = G_full;
opt_dist.Graphs.G = G;
opt_dist.Graphs.G_fault = G_fault;
nv = opt_dist.nAgents    ;
% x_state = [x_agent;u_agent];
opt_dist.x_gt = x_state(:);%10.*rand(1,opt_dist.nAgents*opt_dist.dimAgents)';%[0  0 0.8 0  1.6 0  2.4 0 3.2 0 4 0 4.8 0 5.6 0 6.4 0 7.2 0 ]';

opt_dist.result.gt.x_bar = opt_dist.x_gt;

x0 = opt_dist.x_gt;
x_mean = mean(x0);
figure
imagesc(full(G_fault.Adj))
imagesc(double(G.Adj))

for i=1:nv
    disp([i,sum(G.p(i,:))]);
end
t_mix = 0;
t_pd = 0;
flag_converged = 0;
flag_converged_2 = 0;

falg_pd = 0;
p = G.p;
h_image = figure;
% dataG.h_plot = figure;
% dataG.h_error = figure;
% dataG.h_error2 = figure;
i_time = 1;
opt_dist.i_time = i_time;
% while ~flag_converged && ~flag_converged_2

opt_dist.result.prior.x_cen =  x_state(:);
opt_dist.result.prior.P_cen =  5*opt_dist.motion.Q*eye(opt_dist.dimState);


for i_agent = 1 : opt_dist.nAgents
    
    opt_dist.result.prior.x_bar(:,i_agent) = opt_dist.x_gt + randn(size(opt_dist.x_gt,1),1)*sqrt(5*opt_dist.motion.Q);
    opt_dist.result.prior.P_bar(:,:,i_agent) = 5*opt_dist.motion.Q*eye(opt_dist.dimState);
if opt_dist.FLAGS.compare_with_CI
        opt_dist.result.prior.x_bar_CI(:,i_agent) = opt_dist.result.prior.x_bar(:,i_agent);
    opt_dist.result.prior.P_bar_CI(:,:,i_agent) = opt_dist.result.prior.P_bar(:,:,i_agent);
end
    
end



dataG = make_prediction_initial();
opt_dist.dataG = dataG;

end