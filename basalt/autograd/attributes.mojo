from collections import Optional

from basalt import Tensor, TensorShape
from basalt.nn.tensor import MAX_RANK
from basalt.utils.bytes import Bytes, f64_to_bytes, bytes_to_f64


alias MAX_ATTRS = 10
alias MAX_NAME_CHARS = 16
alias MAX_DATA_BYTES = 32


@value
@register_passable("trivial")
struct AttributeType(Stringable):
    """
    Attributes type.
    """

    alias INT = AttributeType(0, "INT")
    alias FLOAT = AttributeType(1, "FLOAT")
    alias STRING = AttributeType(2, "STRING")
    alias INTS = AttributeType(3, "INTS")
    alias FLOATS = AttributeType(4, "FLOATS")
    alias STRINGS = AttributeType(5, "STRINGS")
    alias TENSOR = AttributeType(6, "TENSOR")
    alias BOOL = AttributeType(7, "BOOL")

    var id: UInt8
    var name: Bytes[16]  # StringLiteral

    fn __init__(inout self, id: UInt8, name: String):
        self.id = id
        self.name = Bytes[16](name)

    fn __eq__(self, other: Self) -> Bool:
        return self.id == other.id

    fn __str__(self) -> String:
        return str(self.name)


@register_passable("trivial")
struct AttributeVector(Sized, Stringable, CollectionElement):
    var attributes: StaticTuple[Attribute, MAX_ATTRS]
    var size: Int

    @always_inline("nodebug")
    fn __init__(inout self, *attributes: Attribute):
        self.attributes = StaticTuple[Attribute, MAX_ATTRS]()
        self.size = len(attributes)
        for i in range(self.size):
            self.attributes[i] = attributes[i]

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        return self.size

    @always_inline("nodebug")
    fn __getitem__(self, index: Int) -> Attribute:
        return self.attributes[index]

    @always_inline("nodebug")
    fn __getitem__(self, index: StringLiteral) -> Optional[Attribute]:
        for i in range(self.size):
            if self.attributes[i].name == Bytes[MAX_NAME_CHARS](index):
                return self.attributes[i]
        return None

    @always_inline("nodebug")
    fn __str__(self) -> String:
        var s: String = "["
        for i in range(self.size):
            s += str(self.attributes[i])
            if i < self.size - 1:
                s += ", "
        return s + "]"


@register_passable("trivial")
struct Attribute(Stringable, CollectionElement):
    var name: Bytes[MAX_NAME_CHARS]
    var data: Bytes[MAX_DATA_BYTES]
    var data_shape: StaticIntTuple[MAX_RANK]
    var type: AttributeType

    @always_inline("nodebug")
    fn __init__(inout self, name: String, value: String):
        self.name = Bytes[MAX_NAME_CHARS](name)
        self.data = Bytes[MAX_DATA_BYTES](value)
        self.data_shape = StaticIntTuple[MAX_RANK]()
        self.data_shape[0] = len(value)
        self.type = AttributeType.STRING

    @always_inline("nodebug")
    fn __init__(inout self, name: String, value: TensorShape):
        self.name = Bytes[MAX_NAME_CHARS](name)
        self.data = Bytes[MAX_DATA_BYTES]()
        self.data_shape = StaticIntTuple[MAX_RANK]()
        self.data[0] = value.rank()
        for i in range(value.rank()):
            self.data_shape[i] = value._shape[i]
        self.type = AttributeType.INTS

    @always_inline("nodebug")
    fn __init__[N: Int](inout self, name: String, value: StaticIntTuple[N]):
        self.name = Bytes[MAX_NAME_CHARS](name)
        self.data = Bytes[MAX_DATA_BYTES]()
        self.data_shape = StaticIntTuple[MAX_RANK]()
        for i in range(N):
            self.data_shape[i] = value[i]
        self.type = AttributeType.INTS

    @always_inline("nodebug")
    fn __init__(inout self, name: String, value: Scalar):
        # BUG: Known bug for big attributes (>1e18, max_finite, inf)
        alias f64_size = DType.float64.sizeof()

        self.name = Bytes[MAX_NAME_CHARS](name)
        self.data = Bytes[MAX_DATA_BYTES]()
        self.data_shape = StaticIntTuple[MAX_RANK]()

        var fbytes = f64_to_bytes(value.cast[DType.float64]().min(1e18))

        @parameter
        fn copy[Index: Int]():
            self.data[Index] = fbytes[Index]

        unroll[copy, f64_size]()

        if value.type.is_bool():
            self.type = AttributeType.BOOL
        elif value.type.is_floating_point():
            self.type = AttributeType.FLOAT
        else:
            self.type = AttributeType.INT

    @always_inline("nodebug")
    fn __init__(inout self, name: String, value: Int):
        self.__init__(name, Float64(value))

    @always_inline("nodebug")
    fn __init__(inout self, name: String, value: FloatLiteral):
        self.__init__(name, Float64(value))

    @always_inline("nodebug")
    fn __str__(self) -> String:
        return "Attribute(" + str(self.name) + ", " + "..." + ")"

    @always_inline("nodebug")
    fn to_string(self) -> String:
        return str(self.data)

    @always_inline("nodebug")
    fn to_shape(self) -> TensorShape:
        return TensorShape(rank=self.data[0].to_int(), shape=self.data_shape)

    @always_inline("nodebug")
    fn to_static[N: Int](self) -> StaticIntTuple[N]:
        var result = StaticIntTuple[N]()
        for i in range(N):
            result[i] = self.data_shape[i]
        return result

    @always_inline("nodebug")
    fn to_scalar[dtype: DType](self) -> Scalar[dtype]:
        alias size = DType.float64.sizeof()

        var fbytes = Bytes[size]()

        @parameter
        fn copy[Index: Int]():
            fbytes[Index] = self.data[Index]

        unroll[copy, size]()

        return bytes_to_f64(fbytes).cast[dtype]()

    @always_inline("nodebug")
    fn to_int(self) -> Int:
        return self.to_scalar[DType.float64]().to_int()

    fn json(self) -> String:
        var result = '{"name": "' + str(self.name) + '", '

        var type: String = ""
        var value: String = ""

        if self.type == AttributeType.STRING:
            type = "STRING"
            value = '"' + self.to_string() + '"'
        elif self.type == AttributeType.INTS:
            type = "INTS"

            var value_temp = self.to_shape()
            value = "["
            for i in range(value_temp.rank()):
                value += str(value_temp._shape[i])
                if i < value_temp.rank() - 1:
                    value += ", "
            value += "]"
        elif self.type == AttributeType.FLOAT:
            type = "FLOAT"
            value = str(self.to_scalar[DType.float64]())
        elif self.type == AttributeType.INT:
            type = "INT"
            value = str(self.to_int())
        else:
            type = "UNKNOWN"
            value = "UNKNOWN"

        result += '"type": "' + type + '", ' + '"value": ' + value

        return result + "}"
