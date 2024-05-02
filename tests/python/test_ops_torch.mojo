from random import rand
from math import exp, log
from python.python import Python
from collections.optional import Optional

from basalt import dtype, nelts
from basalt.nn import Tensor, TensorShape
from basalt.autograd import OP
from basalt.autograd.attributes import Attribute, AttributeVector
from tests import (
    to_numpy,
    to_tensor,
    test_unary_op,
    test_binary_op,
    test_ternary_op,
    test_unary_op_backward,
    test_binary_op_backward,
    test_ternary_op_backward,
)


# ------ Test Binary Ops ------
@value
struct torch_output_binary_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]
    var grad_2: Tensor[dtype]


fn torch_binary_op(
    op: OP, input_1: Tensor, input_2: Tensor, upper_grad: Tensor
) -> torch_output_binary_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)
        var input_2 = torch.from_numpy(to_numpy(input_2)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.ADD:
            expected = input_1 + input_2
        elif op == OP.SUB:
            expected = input_1 - input_2
        elif op == OP.MUL:
            expected = input_1 * input_2
        elif op == OP.DIV:
            expected = input_1 / input_2
        elif op == OP.DOT:
            expected = torch.matmul(input_1, input_2)
        else:
            print("Error: op not supported (returning the default add op result): ", op)
            expected = input_1 + input_2

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        _ = expected.backward(upper_grad)

        return torch_output_binary_op(
            to_tensor(expected.detach().numpy()),
            to_tensor(input_1.grad.numpy()),
            to_tensor(input_2.grad.numpy()),
        )

    except e:
        print("Error importing torch: ", e)
        var d = Tensor[dtype](1)
        return torch_output_binary_op(d, d, d)


fn test_ADD() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias t2_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_binary_op(OP.ADD, t1, t2, ug)

    test_binary_op[OP.ADD, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.ADD, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # broadcasting

    alias t1_shape_2 = TensorShape(37, 63, 107)
    alias t2_shape_2 = TensorShape(37, 63, 1)
    alias ug_shape_2 = TensorShape(37, 63, 107)

    t1 = Tensor[dtype](t1_shape_2)
    t2 = Tensor[dtype](t2_shape_2)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.ADD, t1, t2, ug)

    test_binary_op[OP.ADD, t1_shape_2, t2_shape_2](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.ADD, t1_shape_2, t2_shape_2, ug_shape_2](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


fn test_SUB() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias t2_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_binary_op(OP.SUB, t1, t2, ug)

    test_binary_op[OP.SUB, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.SUB, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # broadcasting

    alias t1_shape_2 = TensorShape(37, 63, 107)
    alias t2_shape_2 = TensorShape(37, 63, 1)
    alias ug_shape_2 = TensorShape(37, 63, 107)

    t1 = Tensor[dtype](t1_shape_2)
    t2 = Tensor[dtype](t2_shape_2)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.SUB, t1, t2, ug)

    test_binary_op[OP.SUB, t1_shape_2, t2_shape_2](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.SUB, t1_shape_2, t2_shape_2, ug_shape_2](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


fn test_MUL() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias t2_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_binary_op(OP.MUL, t1, t2, ug)

    test_binary_op[OP.MUL, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.MUL, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # broadcasting
    alias t1_shape_2 = TensorShape(37, 63, 107)
    alias t2_shape_2 = TensorShape(37, 63, 1)
    alias ug_shape_2 = TensorShape(37, 63, 107)

    t1 = Tensor[dtype](t1_shape_2)
    t2 = Tensor[dtype](t2_shape_2)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.MUL, t1, t2, ug)

    test_binary_op[OP.MUL, t1_shape_2, t2_shape_2](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.MUL, t1_shape_2, t2_shape_2, ug_shape_2](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


fn test_DIV() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias t2_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_binary_op(OP.DIV, t1, t2, ug)

    test_binary_op[OP.DIV, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DIV, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # broadcasting
    alias t1_shape_2 = TensorShape(37, 63, 107)
    alias t2_shape_2 = TensorShape(37, 63, 1)
    alias ug_shape_2 = TensorShape(37, 63, 107)

    t1 = Tensor[dtype](t1_shape_2)
    t2 = Tensor[dtype](t2_shape_2)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.DIV, t1, t2, ug)

    test_binary_op[OP.DIV, t1_shape_2, t2_shape_2](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DIV, t1_shape_2, t2_shape_2, ug_shape_2](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    alias t1_shape_3 = TensorShape(37, 63, 1)
    alias t2_shape_3 = TensorShape(37, 63, 107)
    alias ug_shape_3 = TensorShape(37, 63, 107)

    t1 = Tensor[dtype](t1_shape_3)
    t2 = Tensor[dtype](t2_shape_3)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.DIV, t1, t2, ug)

    test_binary_op[OP.DIV, t1_shape_3, t2_shape_3](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DIV, t1_shape_3, t2_shape_3, ug_shape_3](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


fn test_DOT() raises:
    alias t1_shape = TensorShape(107, 203)
    alias t2_shape = TensorShape(203, 139)
    alias ug_shape = TensorShape(107, 139)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_binary_op(OP.DOT, t1, t2, ug)

    test_binary_op[OP.DOT, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DOT, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # Test same M and N values
    alias t1_shape_2 = TensorShape(107, 186)
    alias t2_shape_2 = TensorShape(186, 107)
    alias ug_shape_2 = TensorShape(107, 107)
    t1 = Tensor[dtype](t1_shape_2)
    t2 = Tensor[dtype](t2_shape_2)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.DOT, t1, t2, ug)

    test_binary_op[OP.DOT, t1_shape_2, t2_shape_2](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DOT, t1_shape_2, t2_shape_2, ug_shape_2](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # Test square matrix
    alias t1_shape_3 = TensorShape(207, 207)
    alias t2_shape_3 = TensorShape(207, 207)
    alias ug_shape_3 = TensorShape(207, 207)
    t1 = Tensor[dtype](t1_shape_3)
    t2 = Tensor[dtype](t2_shape_3)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.DOT, t1, t2, ug)

    test_binary_op[OP.DOT, t1_shape_3, t2_shape_3](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DOT, t1_shape_3, t2_shape_3, ug_shape_3](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )

    # Test with power of 2 values
    alias t1_shape_4 = TensorShape(64, 128)
    alias t2_shape_4 = TensorShape(128, 256)
    alias ug_shape_4 = TensorShape(64, 256)
    t1 = Tensor[dtype](t1_shape_4)
    t2 = Tensor[dtype](t2_shape_4)
    rand(t1.data(), t1.num_elements())
    rand(t2.data(), t2.num_elements())

    ug = Tensor[dtype](ug_shape_4)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_binary_op(OP.DOT, t1, t2, ug)

    test_binary_op[OP.DOT, t1_shape_4, t2_shape_4](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.DOT, t1_shape_4, t2_shape_4, ug_shape_4](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


# ------ Test Unary Ops ------
@value
struct torch_output_unary_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]


fn torch_unary_op(op: OP, input_1: Tensor, upper_grad: Tensor) -> torch_output_unary_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.EXP:
            expected = torch.exp(input_1)
        elif op == OP.LOG:
            expected = torch.log(input_1)
        else:
            print("Error: op not supported (returning the value input_1): ", op)
            expected = input_1

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        _ = expected.backward(upper_grad)

        return torch_output_unary_op(
            to_tensor(expected.detach().numpy()),
            to_tensor(input_1.grad.numpy()),
        )

    except:
        print("Error importing torch")
        var d = Tensor[dtype](1)
        return torch_output_unary_op(d, d)


fn test_EXP() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_unary_op(OP.EXP, t1, ug)

    test_unary_op[OP.EXP, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.EXP, t1_shape, ug_shape](t1, ug, expected_and_grad.grad_1)


fn test_LOG() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_unary_op(OP.LOG, t1, ug)

    test_unary_op[OP.LOG, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.LOG, t1_shape, ug_shape](t1, ug, expected_and_grad.grad_1)


# ------ Test POW ------
@value
struct torch_output_pow_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]
    var grad_2: Tensor[dtype]


fn torch_pow_op(
    op: OP, input_1: Tensor, input_2: Tensor, upper_grad: Tensor
) -> torch_output_pow_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)
        var input_2 = torch.from_numpy(to_numpy(input_2)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.POW:
            expected = torch.pow(input_1, input_2)
        else:
            print("Error: op not supported (returning input 1 value): ", op)
            expected = input_1

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        _ = expected.backward(upper_grad)

        return torch_output_pow_op(
            to_tensor(expected.detach().numpy()),
            to_tensor(input_1.grad.numpy()),
            to_tensor(input_2.grad.numpy()),
        )

    except:
        print("Error importing torch")
        var d = Tensor[dtype](1)
        return torch_output_pow_op(d, d, d)


fn test_POW() raises:
    alias t1_shape = TensorShape(37, 63, 107)
    alias t2_shape = TensorShape(1)
    alias ug_shape = TensorShape(37, 63, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    alias exponent = 3
    var t2 = Tensor[dtype](1)
    t2[0] = exponent

    var expected_and_grad = torch_pow_op(OP.POW, t1, t2, ug)
    test_binary_op[OP.POW, t1_shape, t2_shape](t1, t2, expected_and_grad.expected)
    test_binary_op_backward[OP.POW, t1_shape, t2_shape, ug_shape](
        t1, t2, ug, expected_and_grad.grad_1, expected_and_grad.grad_2
    )


# ------ Test Reduction Ops ------
@value
struct torch_output_reduction_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]


fn torch_reduction_op(
    op: OP, input_1: Tensor, upper_grad: Tensor, axis: Optional[Int] = None
) -> torch_output_reduction_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.SUM:
            if axis:
                expected = torch.sum(input_1, axis.value(), True)
            else:
                expected = torch.sum(input_1)
        elif op == OP.MAX:
            if axis:
                expected = torch.amax(input_1, axis.value(), True)
            else:
                expected = torch.amax(input_1)
        elif op == OP.MEAN:
            if axis:
                expected = torch.mean(input_1, axis.value(), True)
            else:
                expected = torch.mean(input_1)
        else:
            print("Error: op not supported (returning input 1 value): ", op)
            expected = input_1

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        # because torch when working with a tensor of size 1, it considers it as a tensor of size 0 in reality
        if not axis:
            upper_grad = upper_grad.squeeze()
        _ = expected.backward(upper_grad)

        var expected_res: PythonObject
        var grad_1_res = input_1.grad.numpy()
        if not axis:
            expected_res = expected.detach().numpy().reshape(1)
        else:
            expected_res = expected.detach().numpy()

        return torch_output_reduction_op(
            to_tensor(expected_res),
            to_tensor(grad_1_res),
        )

    except e:
        print("Error importing torch: ", e)
        var d = Tensor[dtype](1)
        return torch_output_reduction_op(d, d)


fn test_SUM() raises:
    alias t1_shape = TensorShape(87, 73, 107)
    alias ug_shape = TensorShape(87, 1, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    # 1 axis
    alias axis = 1
    alias attrs = AttributeVector(Attribute("axis", axis))

    var expected_and_grad = torch_reduction_op(OP.SUM, t1, ug, axis)
    test_unary_op[OP.SUM, t1_shape, attrs](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.SUM, t1_shape, ug_shape, attrs](
        t1, ug, expected_and_grad.grad_1
    )

    # 2 axis
    alias ug_shape_2 = TensorShape(87, 73, 1)
    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    alias axis_2 = 2
    alias attrs_2 = AttributeVector(Attribute("axis", axis_2))

    expected_and_grad = torch_reduction_op(OP.SUM, t1, ug, axis_2)
    test_unary_op[OP.SUM, t1_shape, attrs_2](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.SUM, t1_shape, ug_shape_2, attrs_2](
        t1, ug, expected_and_grad.grad_1
    )

    # 0 axis
    alias ug_shape_3 = TensorShape(1, 73, 107)
    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    alias axis_3 = 0
    alias attrs_3 = AttributeVector(Attribute("axis", axis_3))

    expected_and_grad = torch_reduction_op(OP.SUM, t1, ug, axis_3)
    test_unary_op[OP.SUM, t1_shape, attrs_3](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.SUM, t1_shape, ug_shape_3, attrs_3](
        t1, ug, expected_and_grad.grad_1
    )

    # all dims
    alias ug_shape_4 = TensorShape(1)
    ug = Tensor[dtype](ug_shape_4)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_reduction_op(OP.SUM, t1, ug)

    test_unary_op[OP.SUM, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.SUM, t1_shape, ug_shape_4](
        t1, ug, expected_and_grad.grad_1
    )


fn test_MAX() raises:
    alias t1_shape = TensorShape(87, 73, 107)
    alias ug_shape = TensorShape(87, 1, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    # 1 axis
    alias axis = 1
    alias attrs = AttributeVector(Attribute("axis", axis))

    var expected_and_grad = torch_reduction_op(OP.MAX, t1, ug, axis)
    test_unary_op[OP.MAX, t1_shape, attrs](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MAX, t1_shape, ug_shape, attrs](
        t1, ug, expected_and_grad.grad_1
    )

    # 2 axis
    alias ug_shape_2 = TensorShape(87, 73, 1)
    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    alias axis_2 = 2
    alias attrs_2 = AttributeVector(Attribute("axis", axis_2))

    expected_and_grad = torch_reduction_op(OP.MAX, t1, ug, axis_2)
    test_unary_op[OP.MAX, t1_shape, attrs_2](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MAX, t1_shape, ug_shape_2, attrs_2](
        t1, ug, expected_and_grad.grad_1
    )

    # 0 axis
    alias ug_shape_3 = TensorShape(1, 73, 107)
    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    alias axis_3 = 0
    alias attrs_3 = AttributeVector(Attribute("axis", axis_3))

    expected_and_grad = torch_reduction_op(OP.MAX, t1, ug, axis_3)
    test_unary_op[OP.MAX, t1_shape, attrs_3](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MAX, t1_shape, ug_shape_3, attrs_3](
        t1, ug, expected_and_grad.grad_1
    )

    # all dims
    alias ug_shape_4 = TensorShape(1)
    ug = Tensor[dtype](ug_shape_4)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_reduction_op(OP.MAX, t1, ug)
    test_unary_op[OP.MAX, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MAX, t1_shape, ug_shape_4](
        t1, ug, expected_and_grad.grad_1
    )


fn test_MEAN() raises:
    alias t1_shape = TensorShape(87, 73, 107)
    alias ug_shape = TensorShape(87, 1, 107)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    # 1 axis
    alias axis = 1
    alias attrs = AttributeVector(Attribute("axis", axis))

    var expected_and_grad = torch_reduction_op(OP.MEAN, t1, ug, axis)
    test_unary_op[OP.MEAN, t1_shape, attrs](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MEAN, t1_shape, ug_shape, attrs](
        t1, ug, expected_and_grad.grad_1
    )

    # 2 axis
    alias ug_shape_2 = TensorShape(87, 73, 1)
    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    alias axis_2 = 2
    alias attrs_2 = AttributeVector(Attribute("axis", axis_2))

    expected_and_grad = torch_reduction_op(OP.MEAN, t1, ug, axis_2)
    test_unary_op[OP.MEAN, t1_shape, attrs_2](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MEAN, t1_shape, ug_shape_2, attrs_2](
        t1, ug, expected_and_grad.grad_1
    )

    # 0 axis
    alias ug_shape_3 = TensorShape(1, 73, 107)
    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    alias axis_3 = 0
    alias attrs_3 = AttributeVector(Attribute("axis", axis_3))

    expected_and_grad = torch_reduction_op(OP.MEAN, t1, ug, axis_3)
    test_unary_op[OP.MEAN, t1_shape, attrs_3](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MEAN, t1_shape, ug_shape_3, attrs_3](
        t1, ug, expected_and_grad.grad_1
    )

    # all dims
    alias ug_shape_4 = TensorShape(1)
    ug = Tensor[dtype](ug_shape_4)
    rand(ug.data(), ug.num_elements())

    expected_and_grad = torch_reduction_op(OP.MEAN, t1, ug)
    test_unary_op[OP.MEAN, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.MEAN, t1_shape, ug_shape_4](
        t1, ug, expected_and_grad.grad_1
    )


# ------ Test transformation Ops ------
@value
struct torch_output_transform_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]


fn torch_transform_op(
    op: OP, input_1: Tensor, upper_grad: Tensor, new_shape: PythonObject = None
) -> torch_output_transform_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.FLATTEN:
            expected = input_1.flatten()
        elif op == OP.RESHAPE:
            expected = input_1.reshape(new_shape)
        elif op == OP.TRANSPOSE:
            expected = input_1.permute(new_shape)
        else:
            print("Error: op not supported (returning input 1 value): ", op)
            expected = input_1

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        _ = expected.backward(upper_grad)

        return torch_output_transform_op(
            to_tensor(expected.detach().numpy()),
            to_tensor(input_1.grad.numpy()),
        )

    except e:
        print("Error importing torch: ", e)
        var d = Tensor[dtype](1)
        return torch_output_transform_op(d, d)


fn test_FLATTEN() raises:
    alias t1_shape = TensorShape(87, 73, 84)
    alias ug_shape = TensorShape(t1_shape.num_elements())
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    var expected_and_grad = torch_transform_op(OP.FLATTEN, t1, ug, None)
    test_unary_op[OP.FLATTEN, t1_shape](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.FLATTEN, t1_shape, ug_shape](
        t1, ug, expected_and_grad.grad_1
    )


fn test_RESHAPE() raises:
    alias t1_shape = TensorShape(87, 73, 84)
    alias ug_shape = TensorShape(87, 73 * 84)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    alias new_shape = TensorShape(87, 73 * 84)
    alias new_shape_tuple = (new_shape[0], new_shape[1])
    alias attrs = AttributeVector(Attribute("shape", new_shape))

    var expected_and_grad = torch_transform_op(OP.RESHAPE, t1, ug, new_shape_tuple)
    test_unary_op[OP.RESHAPE, t1_shape, attrs](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.RESHAPE, t1_shape, ug_shape, attrs](
        t1, ug, expected_and_grad.grad_1
    )


fn test_TRANSPOSE() raises:
    alias t1_shape = TensorShape(87, 73, 84)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    alias ug_shape = TensorShape(73, 84, 87)
    var ug = Tensor[dtype](ug_shape)
    rand(ug.data(), ug.num_elements())

    alias axes = TensorShape(1, 2, 0)
    alias axes_tuple = (axes[0], axes[1], axes[2])
    alias attrs = AttributeVector(Attribute("axes", axes))

    var expected_and_grad = torch_transform_op(OP.TRANSPOSE, t1, ug, axes_tuple)
    test_unary_op[OP.TRANSPOSE, t1_shape, attrs](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.TRANSPOSE, t1_shape, ug_shape, attrs](
        t1, ug, expected_and_grad.grad_1
    )

    # Test reverse axis
    alias ug_shape_2 = TensorShape(84, 73, 87)
    ug = Tensor[dtype](ug_shape_2)
    rand(ug.data(), ug.num_elements())

    alias axes_2 = TensorShape(2, 1, 0)
    alias axes_tuple_2 = (axes_2[0], axes_2[1], axes_2[2])
    alias attrs_2 = AttributeVector(Attribute("axes", axes_2))

    expected_and_grad = torch_transform_op(OP.TRANSPOSE, t1, ug, axes_tuple_2)
    test_unary_op[OP.TRANSPOSE, t1_shape, attrs_2](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.TRANSPOSE, t1_shape, ug_shape_2, attrs_2](
        t1, ug, expected_and_grad.grad_1
    )

    # Test with rank 2 tensor
    alias t1_shape_3 = TensorShape(87, 73)
    t1 = Tensor[dtype](t1_shape_3)
    rand(t1.data(), t1.num_elements())

    alias ug_shape_3 = TensorShape(73, 87)
    ug = Tensor[dtype](ug_shape_3)
    rand(ug.data(), ug.num_elements())

    alias axes_3 = TensorShape(1, 0)
    alias axes_tuple_3 = (axes_3[0], axes_3[1])
    alias attrs_3 = AttributeVector(Attribute("axes", axes_3))

    expected_and_grad = torch_transform_op(OP.TRANSPOSE, t1, ug, axes_tuple_3)
    test_unary_op[OP.TRANSPOSE, t1_shape_3, attrs_3](t1, expected_and_grad.expected)
    test_unary_op_backward[OP.TRANSPOSE, t1_shape_3, ug_shape_3, attrs_3](
        t1, ug, expected_and_grad.grad_1
    )


# ------ Test ternary Ops ------
@value
struct torch_output_ternary_op:
    var expected: Tensor[dtype]
    var grad_1: Tensor[dtype]
    var grad_2: Tensor[dtype]
    var grad_3: Tensor[dtype]


fn torch_ternary_op(
    op: OP, input_1: Tensor, input_2: Tensor, input_3: Tensor, upper_grad: Tensor
) -> torch_output_ternary_op:
    try:
        var torch = Python.import_module("torch")
        var np = Python.import_module("numpy")

        var input_1 = torch.from_numpy(to_numpy(input_1)).requires_grad_(True)
        var input_2 = torch.from_numpy(to_numpy(input_2)).requires_grad_(True)
        var input_3 = torch.from_numpy(to_numpy(input_3)).requires_grad_(True)

        var expected: PythonObject

        if op == OP.FMA:
            expected = input_1 * input_2 + input_3
        else:
            print("Error: op not supported (returning input 1 value): ", op)
            expected = input_1

        # uppergrad & backwards
        var upper_grad = torch.from_numpy(to_numpy(upper_grad))
        _ = expected.backward(upper_grad)

        return torch_output_ternary_op(
            to_tensor(expected.detach().numpy()),
            to_tensor(input_1.grad.numpy()),
            to_tensor(input_2.grad.numpy()),
            to_tensor(input_3.grad.numpy()),
        )

    except e:
        print("Error importing torch: ", e)
        var d = Tensor[dtype](1)
        return torch_output_ternary_op(d, d, d, d)


fn test_FMA() raises:
    alias t1_shape = TensorShape(87, 73, 84)
    alias t2_shape = TensorShape(87, 73, 84)
    alias t3_shape = TensorShape(87, 73, 84)
    var t1: Tensor[dtype] = Tensor[dtype](t1_shape)
    rand(t1.data(), t1.num_elements())

    var t2: Tensor[dtype] = Tensor[dtype](t2_shape)
    rand(t2.data(), t2.num_elements())

    var t3: Tensor[dtype] = Tensor[dtype](t3_shape)
    rand(t3.data(), t3.num_elements())

    var expected_and_grad = torch_ternary_op(OP.FMA, t1, t2, t3, t1)

    test_ternary_op[OP.FMA, t1_shape, t2_shape, t3_shape](
        t1, t2, t3, expected_and_grad.expected
    )
    test_ternary_op_backward[OP.FMA, t1_shape, t2_shape, t3_shape, t1_shape](
        t1,
        t2,
        t3,
        t1,
        expected_and_grad.grad_1,
        expected_and_grad.grad_2,
        expected_and_grad.grad_3,
    )


fn main():
    print("Running ops (compare with torch) tests")
    try:
        test_ADD()
        test_SUB()
        test_MUL()
        test_DIV()
        test_DOT()
        test_EXP()
        test_LOG()
        test_POW()
        test_SUM()
        test_MAX()
        test_MEAN()
        test_FLATTEN()
        test_RESHAPE()
        test_TRANSPOSE()
        test_FMA()
    except e:
        print("[ERROR] Error in ops (compare with torch)")
        print(e)
        return

    print("Finished ops (compare with torch) tests")
