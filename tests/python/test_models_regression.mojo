from random import rand
from python import Python
from utils.numerics import max_finite
from testing import assert_almost_equal

from basalt import dtype
from basalt.autograd import Graph, OP
from basalt.nn import Tensor, TensorShape, Model, MSELoss, optim
from basalt.utils.rand_utils import MersenneTwister

from tests import to_numpy, to_tensor


fn create_linear_regression(
    batch_size: Int,
    n_outputs: Int,
    linear1_weights: List[Scalar[dtype]],
    linear1_bias: List[Scalar[dtype]],
) -> Graph:
    var g = Graph()
    var x = g.input(TensorShape(batch_size, 13))

    # linear1
    # var out = nn.Linear(g, x, n_outputs=1)
    var l1_w = g.param(TensorShape(13, n_outputs), init=linear1_weights)
    var l1_b = g.param(TensorShape(n_outputs), init=linear1_bias)
    var res = g.op(OP.DOT, x, l1_w)
    var out = g.op(OP.ADD, res, l1_b)
    g.out(out)

    var y_true = g.input(TensorShape(batch_size, n_outputs))
    var loss = MSELoss(g, out, y_true)
    g.loss(loss)

    return g ^


fn run_mojo[
    batch_size: Int,
    n_outputs: Int,
    linear1_weights: List[Scalar[dtype]],
    linear1_bias: List[Scalar[dtype]],
](
    epochs: Int,
    learning_rate: Float64,
    inputs: Tensor[dtype],
    labels: Tensor[dtype],
) -> List[Scalar[dtype]]:
    alias graph = create_linear_regression(
        batch_size,
        n_outputs,
        linear1_weights,
        linear1_bias,
    )

    var model = Model[graph]()
    var optim = optim.Adam[graph](Reference(model.parameters), lr=learning_rate)

    var losses = List[Scalar[dtype]]()

    for i in range(epochs):
        var loss = model.forward(inputs, labels)

        # Backward pass
        optim.zero_grad()
        model.backward()
        optim.step()

        losses.append(loss[0])

    return losses


fn run_torch(
    epochs: Int,
    learning_rate: Float64,
    inputs: Tensor,
    labels: Tensor,
    owned linear1_weights: Tensor,
    owned linear1_bias: Tensor,
) -> List[Scalar[dtype]]:
    var out: List[Scalar[dtype]] = List[Scalar[dtype]]()

    try:
        var torch = Python.import_module("torch")
        var F = Python.import_module("torch.nn.functional")
        var np = Python.import_module("numpy")
        Python.add_to_path("./tests/python")
        var torch_models = Python.import_module("test_models_torch")

        var inputs = torch.from_numpy(to_numpy(inputs)).requires_grad_(True)
        var labels = torch.from_numpy(to_numpy(labels)).requires_grad_(True)

        var linear1_weights = torch.from_numpy(
            to_numpy(linear1_weights)
        ).requires_grad_(True)
        var linear1_bias = torch.from_numpy(to_numpy(linear1_bias)).requires_grad_(True)

        var regression = torch_models.LinearRegression(
            linear1_weights,
            linear1_bias,
        )

        var loss_func = torch_models.MSELoss()
        var optimizer = torch.optim.Adam(regression.parameters(), learning_rate)

        for i in range(epochs):
            var output = regression.forward(inputs)
            var loss = loss_func(output, labels)

            _ = optimizer.zero_grad()
            _ = loss.backward()
            _ = optimizer.step()

            out.append(to_tensor(loss)[0].cast[dtype]())

        return out

    except e:
        print("Error importing torch")
        print(e)
        return out


fn create_weights(num_elements: Int, zero: Bool) -> List[Scalar[dtype]]:
    var prng = MersenneTwister(123456)
    var weights = List[Scalar[dtype]](capacity=num_elements)
    for i in range(num_elements):
        if zero:
            weights.append(Scalar[dtype](0.0))
        else:
            var rand_float = prng.next().cast[dtype]() / max_finite[DType.int32]().cast[
                dtype
            ]()
            weights.append(Scalar[dtype](rand_float / 10))
    return weights ^


fn dv_to_tensor(dv: List[Scalar[dtype]], shape: TensorShape) -> Tensor[dtype]:
    var t = Tensor[dtype](shape)
    if t.num_elements() != len(dv):
        print("[WARNING] tensor and dv not the shame shape")
    for i in range(t.num_elements()):
        t[i] = dv[i]
    return t ^


fn main():
    alias learning_rate = 1e-3
    alias epochs = 100
    alias batch_size = 64
    alias n_outputs = 10

    var inputs = Tensor[dtype](batch_size, 13)
    rand[dtype](inputs.data(), inputs.num_elements())
    var labels = Tensor[dtype](batch_size, n_outputs)
    for i in range(batch_size):
        for j in range(n_outputs):
            labels[i * n_outputs + j] = 1

    alias l1_w_shape = TensorShape(13, n_outputs)
    alias linear1_weights = create_weights(l1_w_shape.num_elements(), zero=False)
    alias l1_b_shape = TensorShape(n_outputs)
    alias linear1_bias = create_weights(l1_b_shape.num_elements(), zero=False)

    var losses_mojo = run_mojo[batch_size, n_outputs, linear1_weights, linear1_bias,](
        epochs,
        learning_rate,
        inputs,
        labels,
    )

    var losses_torch = run_torch(
        epochs,
        learning_rate,
        inputs,
        labels,
        dv_to_tensor(linear1_weights, l1_w_shape),
        dv_to_tensor(linear1_bias, l1_b_shape),
    )

    var success = True
    for i in range(epochs):
        var loss_mojo = losses_mojo[i]
        var loss_torch = losses_torch[i]
        # print("loss_mojo: ", loss_mojo, " loss_torch: ", loss_torch)
        try:
            assert_almost_equal(loss_mojo, loss_torch, rtol=1e-4)
        except e:
            print("Losses not equal")
            print(e)
            success = False
            break

    if success:
        print("SUCCES: All losses in Linear Regression model are equal.")
