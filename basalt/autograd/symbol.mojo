from basalt import Tensor, TensorShape
from basalt.utils.uuid import UUID


@register_passable("trivial")
struct Symbol(CollectionElement, Stringable):
    var name: UUID
    var dtype: DType
    var shape: TensorShape
    var trainable: Bool

    fn __init__(
        inout self, name: UUID, dtype: DType, shape: TensorShape, trainable: Bool
    ):
        self.name = name
        self.shape = shape
        self.dtype = dtype
        self.trainable = trainable

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name

    fn __str__(self) -> String:
        return self.json()

    fn json(self) -> String:
        return (
            '{"name": "'
            + str(self.name)[:8]
            + '", "dtype": "'
            + str(self.dtype)
            + '", "shape": "'
            + str(self.shape)
            + '"}'
        )
