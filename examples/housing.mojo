from time.time import now

import basalt.nn as nn
from basalt import Tensor, TensorShape
from basalt import Graph, Symbol, OP
from basalt.utils.datasets import BostonHousing
from basalt.utils.dataloader import DataLoader
from basalt.nn.model import Parameters


fn linear_regression(batch_size: Int, n_inputs: Int, n_outputs: Int) -> Graph:
    var g = Graph()

    var x = g.input(TensorShape(batch_size, n_inputs))
    var y_true = g.input(TensorShape(batch_size, n_outputs))

    var y_pred = nn.Linear(g, x, n_outputs)
    g.out(y_pred)

    var loss = nn.MSELoss(g, y_pred, y_true)
    g.loss(loss)

    return g ^


fn main():
    # Train Parameters
    alias batch_size = 32
    alias num_epochs = 200
    alias learning_rate = 0.02

    alias graph = linear_regression(batch_size, 13, 1)

    # try: graph.render("operator")
    # except: print("Could not render graph")

    var model = nn.Model[graph]()
    var optim = nn.optim.Adam[graph](model.parameters, lr=learning_rate)

    # Batchwise data loader
    print("Loading data...")
    var train_data: BostonHousing
    try:
        train_data = BostonHousing(file_path="./examples/data/housing.csv")
    except:
        print("Could not load data")
        return

    var training_loader = DataLoader(
        data=train_data.data, labels=train_data.labels, batch_size=batch_size
    )

    print("Training started.")
    var start = now()
    for epoch in range(num_epochs):
        var num_batches: Int = 0
        var epoch_loss: Float32 = 0.0
        for batch in training_loader:
            # Forward pass
            var loss = model.forward(batch.data, batch.labels)

            # Backward pass
            optim.zero_grad()
            model.backward()
            optim.step()

            epoch_loss += loss[0]
            num_batches += 1

        print(
            "Epoch: [",
            epoch + 1,
            "/",
            num_epochs,
            "] \t Avg loss per epoch:",
            epoch_loss / num_batches,
        )

    print("Training finished: ", (now() - start) / 1e9, "seconds")

    # print("\n\nInferencing model...\n")
    # for batch in training_loader:
    #     var output = model.inference(batch.data)

    #     # Print first (and only output)
    #     print("Predicted: ", output[0])
