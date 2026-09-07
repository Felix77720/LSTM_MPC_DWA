function layers = build_lstm_network(cfg)
% build_lstm_network - Build the many-to-one LSTM trajectory prediction network.
%
% Input:
%   cfg - config struct with fields dyn.numFeatures, dyn.N_pred, dyn.hidden,
%         and dyn.dropout.
% Output:
%   layers - layer array whose sequence input has numFeatures channels and
%            whose regression output has 3*N_pred channels (future
%            displacements over N_pred steps).

numFeatures = cfg.dyn.numFeatures;
N_pred      = cfg.dyn.N_pred;
hidden      = cfg.dyn.hidden;

layers = [
    sequenceInputLayer(numFeatures, 'Name', 'input')
    lstmLayer(hidden, 'OutputMode', 'last', 'Name', 'lstm')
    dropoutLayer(cfg.dyn.dropout, 'Name', 'drop')
    fullyConnectedLayer(hidden, 'Name', 'fc1')
    reluLayer('Name', 'relu')
    fullyConnectedLayer(3 * N_pred, 'Name', 'fc_out')
    regressionLayer('Name', 'reg')
];
end
