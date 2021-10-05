// RUN: torch-mlir-opt -torch-reduce-op-variants  %s | FileCheck %s

// CHECK-LABEL:   func @convert_to_value_semantic_tensors(
// CHECK-SAME:                                       %[[ARG:.*]]: !torch.tensor<[],f32>) -> !torch.tensor<[],f32> {
// CHECK:           %[[OPERAND_TENSOR:.*]] = torch.copy.to_vtensor %[[ARG]] : !torch.vtensor<[],f32>
// CHECK:           %[[RESULT_TENSOR:.*]] = torch.aten.tanh %[[OPERAND_TENSOR]] : !torch.vtensor<[],f32> -> !torch.vtensor<[],f32>
// CHECK:           %[[RET:.*]] = torch.copy.to_tensor %[[RESULT_TENSOR]] : !torch.tensor<[],f32>
// CHECK:           return %[[RET]] : !torch.tensor<[],f32>
func @convert_to_value_semantic_tensors(%arg0: !torch.tensor<[],f32>) -> !torch.tensor<[],f32> {
  %0 = torch.aten.tanh %arg0 : !torch.tensor<[],f32> -> !torch.tensor<[],f32>
  return %0 : !torch.tensor<[],f32>
}

// CHECK-LABEL:   func @convert_to_value_semantic_tensors_list(
// CHECK-SAME:                  %[[VT0:.*]]: !torch.vtensor, %[[VT1:.*]]: !torch.vtensor,
// CHECK-SAME:                  %[[VT2:.*]]: !torch.vtensor) -> !torch.tensor {
// CHECK:           %[[T0:.*]] = torch.copy.to_tensor %[[VT0]] : !torch.tensor
// CHECK:           %[[T1:.*]] = torch.copy.to_tensor %[[VT1]] : !torch.tensor
// CHECK:           %[[T2:.*]] = torch.copy.to_tensor %[[VT2]] : !torch.tensor
// CHECK:           %[[DIM:.*]] = torch.constant.int 1
// CHECK:           %[[LIST_ORIG:.*]] = torch.prim.ListConstruct %[[T0]], %[[T1]], %[[T2]] :
// CHECK-SAME:          (!torch.tensor, !torch.tensor, !torch.tensor) -> !torch.list<!torch.tensor>
// CHECK:           %[[VT0_COPY:.*]] = torch.copy.to_vtensor %[[T0]] : !torch.vtensor
// CHECK:           %[[VT1_COPY:.*]] = torch.copy.to_vtensor %[[T1]] : !torch.vtensor
// CHECK:           %[[VT2_COPY:.*]] = torch.copy.to_vtensor %[[T2]] : !torch.vtensor
// CHECK:           %[[LIST_NEW:.*]] = torch.prim.ListConstruct
// CHECK-SAME:          %[[VT0_COPY]], %[[VT1_COPY]], %[[VT2_COPY]] :
// CHECK-SAME:          (!torch.vtensor, !torch.vtensor, !torch.vtensor) -> !torch.list<!torch.vtensor>
// CHECK:           %[[VRET:.*]] = torch.aten.cat %[[LIST_NEW]], %[[DIM]] :
// CHECK-SAME:          !torch.list<!torch.vtensor>, !torch.int -> !torch.vtensor
// CHECK:           %[[RET:.*]] = torch.copy.to_tensor %[[VRET]] : !torch.tensor
// CHECK:           return %[[RET]] : !torch.tensor
func @convert_to_value_semantic_tensors_list(%vt0: !torch.vtensor, %vt1: !torch.vtensor, %vt2: !torch.vtensor) -> !torch.tensor {
  %t0 = torch.copy.to_tensor %vt0 : !torch.tensor
  %t1 = torch.copy.to_tensor %vt1 : !torch.tensor
  %t2 = torch.copy.to_tensor %vt2 : !torch.tensor
  %int1 = torch.constant.int 1
  %list = torch.prim.ListConstruct %t0, %t1, %t2 : (!torch.tensor, !torch.tensor, !torch.tensor) -> !torch.list<!torch.tensor>
  %ret = torch.aten.cat %list, %int1 : !torch.list<!torch.tensor>, !torch.int -> !torch.tensor
  return %ret : !torch.tensor
}

// CHECK-LABEL:   func @convert_to_value_semantic_tensors_optional(
// CHECK-SAME:         %[[INPUT:.*]]: !torch.tensor, %[[FLOAT_TENSOR:.*]]: !torch.tensor<[4],f32>,
// CHECK-SAME:         %[[TRAINING:.*]]: !torch.bool, %[[CUDNN_ENABLE:.*]]: !torch.bool,
// CHECK-SAME:         %[[FLOAT:.*]]: !torch.float) -> !torch.tensor {
// CHECK:           %[[NONE:.*]] = torch.constant.none
// CHECK:           %[[FLOAT_TENSOR_OPTIONAL:.*]] = torch.derefine %[[FLOAT_TENSOR]] :
// CHECK-SAME:         !torch.tensor<[4],f32> to !torch.optional<!torch.tensor>
// CHECK:           %[[BIAS_NONE_OPTIONAL:.*]] = torch.derefine %[[NONE]] : !torch.none to !torch.optional<!torch.tensor>
// CHECK:           %[[VINPUT:.*]] = torch.copy.to_vtensor %[[INPUT]] : !torch.vtensor
// CHECK:           %[[FLOAT_VTENSOR:.*]] = torch.copy.to_vtensor %[[FLOAT_TENSOR]] : !torch.vtensor<[4],f32>
// CHECK:           %[[WEIGHTS_TENSOR_OPTIONAL:.*]] = torch.derefine %[[FLOAT_VTENSOR]] :
// CHECK-SAME:         !torch.vtensor<[4],f32> to !torch.optional<!torch.vtensor<[4],f32>>
// CHECK:           %[[FLOAT_VTENSOR:.*]] = torch.copy.to_vtensor %[[FLOAT_TENSOR]] : !torch.vtensor<[4],f32>
// CHECK:           %[[MEAN_VTENSOR_OPTIONAL:.*]] = torch.derefine %[[FLOAT_VTENSOR]] :
// CHECK-SAME:         !torch.vtensor<[4],f32> to !torch.optional<!torch.vtensor<[4],f32>>
// CHECK:           %[[FLOAT_VTENSOR:.*]] = torch.copy.to_vtensor %[[FLOAT_TENSOR]] : !torch.vtensor<[4],f32>
// CHECK:           %[[VAR_VTENSOR_OPTIONAL:.*]] = torch.derefine %[[FLOAT_VTENSOR]] :
// CHECK-SAME:         !torch.vtensor<[4],f32> to !torch.optional<!torch.vtensor<[4],f32>>
// CHECK:           %[[VRET:.*]] = torch.aten.batch_norm %[[VINPUT]], %[[WEIGHTS_TENSOR_OPTIONAL]],
// CHECK-SAME:         %[[BIAS_NONE_OPTIONAL]], %[[MEAN_VTENSOR_OPTIONAL]], %[[VAR_VTENSOR_OPTIONAL]],
// CHECK-SAME:         %[[TRAINING]], %[[FLOAT]], %[[FLOAT]], %[[CUDNN_ENABLE]] :
// CHECK-SAME:         !torch.vtensor, !torch.optional<!torch.vtensor<[4],f32>>, !torch.optional<!torch.tensor>,
// CHECK-SAME:         !torch.optional<!torch.vtensor<[4],f32>>, !torch.optional<!torch.vtensor<[4],f32>>,
// CHECK-SAME:         !torch.bool, !torch.float, !torch.float, !torch.bool -> !torch.vtensor
// CHECK:           %[[RET:.*]] = torch.copy.to_tensor %[[VRET]] : !torch.tensor
// CHECK:           return %[[RET]] : !torch.tensor
// CHECK:         }
func @convert_to_value_semantic_tensors_optional(%t: !torch.tensor,
                                                 %ft: !torch.tensor<[4],f32>,
                                                 %training: !torch.bool,
                                                 %cudnn_enable: !torch.bool,
                                                 %f : !torch.float) -> !torch.tensor {
    %none = torch.constant.none
    %tensor_optional = torch.derefine %ft: !torch.tensor<[4],f32> to !torch.optional<!torch.tensor>
    %none_optional = torch.derefine %none : !torch.none to !torch.optional<!torch.tensor>
    %ret = torch.aten.batch_norm %t, %tensor_optional, %none_optional, %tensor_optional,
              %tensor_optional, %training, %f, %f, %cudnn_enable:
              !torch.tensor, !torch.optional<!torch.tensor>, !torch.optional<!torch.tensor>,
              !torch.optional<!torch.tensor>, !torch.optional<!torch.tensor>,
              !torch.bool, !torch.float, !torch.float, !torch.bool -> !torch.tensor
    return %ret: !torch.tensor
}

// CHECK-LABEL:   func @reduce_trailing_underscore_inplace_variant(
// CHECK-SAME:                          %[[ARG0:.*]]: !torch.tensor<[2,2],f32>,
// CHECK-SAME:                          %[[ARG1:.*]]: !torch.tensor<[2,2],f32>) -> (!torch.tensor<[2,2],f32>, !torch.tensor<[2,2],f32>) {
// CHECK:           %[[C1:.*]] = torch.constant.int 1
// CHECK:           %[[TENSOR0:.*]] = torch.copy.to_vtensor %[[ARG0]] : !torch.vtensor<[2,2],f32>
// CHECK:           %[[TENSOR1:.*]] = torch.copy.to_vtensor %[[ARG1]] : !torch.vtensor<[2,2],f32>
// CHECK:           %[[TENSOR_RESULT:.*]] = torch.aten.add.Tensor %[[TENSOR0]], %[[TENSOR1]], %[[C1]] : !torch.vtensor<[2,2],f32>, !torch.vtensor<[2,2],f32>, !torch.int -> !torch.vtensor<[2,2],f32>
// Note: This somewhat redundant conversion back and forth
// (which is cleaned up by canonicalization) is an artifact of two patterns
// being applied in sequence.
// CHECK:           %[[ARRAY_RESULT:.*]] = torch.copy.to_tensor %[[TENSOR_RESULT]] : !torch.tensor<[2,2],f32>
// CHECK:           %[[TENSOR_AGAIN:.*]] = torch.copy.to_vtensor %[[ARRAY_RESULT]] : !torch.vtensor<[2,2],f32>
// CHECK:           torch.overwrite.tensor %[[TENSOR_AGAIN]] overwrites %[[ARG0]] : !torch.vtensor<[2,2],f32>, !torch.tensor<[2,2],f32>
// CHECK:           return %[[ARG0]], %[[ARG0]] : !torch.tensor<[2,2],f32>, !torch.tensor<[2,2],f32>
func @reduce_trailing_underscore_inplace_variant(%arg0: !torch.tensor<[2,2],f32>, %arg1: !torch.tensor<[2,2],f32>) -> (!torch.tensor<[2,2],f32>, !torch.tensor<[2,2],f32>) {
  %c1 = torch.constant.int 1
  %0 = torch.aten.add_.Tensor %arg0, %arg1, %c1 : !torch.tensor<[2,2],f32>, !torch.tensor<[2,2],f32>, !torch.int -> !torch.tensor<[2,2],f32>
  return %0, %arg0 : !torch.tensor<[2,2],f32>, !torch.tensor<[2,2],f32>
}

// CHECK-LABEL:   func @torch.tensor.literal() -> !torch.tensor {
// CHECK:           %[[VTENSOR:.*]] = torch.vtensor.literal(dense<0.000000e+00> : tensor<7xf32>) : !torch.vtensor<[7],f32>
// CHECK:           %[[SIZES_ERASED:.*]] = torch.tensor_static_info_cast %[[VTENSOR]] : !torch.vtensor<[7],f32> to !torch.vtensor
// CHECK:           %[[TENSOR:.*]] = torch.copy.to_tensor %[[SIZES_ERASED]] : !torch.tensor
// CHECK:           return %[[TENSOR]] : !torch.tensor
func @torch.tensor.literal() -> !torch.tensor {
  %0 = torch.tensor.literal(dense<0.0> : tensor<7xf32>) : !torch.tensor
  return %0 : !torch.tensor
}