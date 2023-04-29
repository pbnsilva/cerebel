# Generated by the gRPC Python protocol compiler plugin. DO NOT EDIT!
import grpc

import scrapers.store_pb2 as store__pb2


class ProductStoreStub(object):
  # missing associated documentation comment in .proto file
  pass

  def __init__(self, channel):
    """Constructor.

    Args:
      channel: A grpc.Channel.
    """
    self.Create = channel.unary_unary(
        '/store.ProductStore/Create',
        request_serializer=store__pb2.CreateRequest.SerializeToString,
        response_deserializer=store__pb2.CreateResponse.FromString,
        )
    self.Delete = channel.unary_unary(
        '/store.ProductStore/Delete',
        request_serializer=store__pb2.DeleteRequest.SerializeToString,
        response_deserializer=store__pb2.DeleteResponse.FromString,
        )
    self.BulkGetItemsByID = channel.unary_unary(
        '/store.ProductStore/BulkGetItemsByID',
        request_serializer=store__pb2.BulkGetItemsByIDRequest.SerializeToString,
        response_deserializer=store__pb2.BulkGetItemsByIDResponse.FromString,
        )
    self.BulkUpsertItems = channel.unary_unary(
        '/store.ProductStore/BulkUpsertItems',
        request_serializer=store__pb2.BulkUpsertItemsRequest.SerializeToString,
        response_deserializer=store__pb2.BulkUpsertItemsResponse.FromString,
        )
    self.BulkDeleteItemsByID = channel.unary_unary(
        '/store.ProductStore/BulkDeleteItemsByID',
        request_serializer=store__pb2.BulkDeleteItemsByIDRequest.SerializeToString,
        response_deserializer=store__pb2.BulkDeleteItemsByIDResponse.FromString,
        )
    self.ListItems = channel.unary_stream(
        '/store.ProductStore/ListItems',
        request_serializer=store__pb2.ListItemsRequest.SerializeToString,
        response_deserializer=store__pb2.Item.FromString,
        )
    self.ListItemsForBrand = channel.unary_stream(
        '/store.ProductStore/ListItemsForBrand',
        request_serializer=store__pb2.ListItemsForBrandRequest.SerializeToString,
        response_deserializer=store__pb2.Item.FromString,
        )
    self.GenerateReadToken = channel.unary_unary(
        '/store.ProductStore/GenerateReadToken',
        request_serializer=store__pb2.GenerateReadTokenRequest.SerializeToString,
        response_deserializer=store__pb2.GenerateReadTokenResponse.FromString,
        )


class ProductStoreServicer(object):
  # missing associated documentation comment in .proto file
  pass

  def Create(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def Delete(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def BulkGetItemsByID(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def BulkUpsertItems(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def BulkDeleteItemsByID(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def ListItems(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def ListItemsForBrand(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def GenerateReadToken(self, request, context):
    # missing associated documentation comment in .proto file
    pass
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')


def add_ProductStoreServicer_to_server(servicer, server):
  rpc_method_handlers = {
      'Create': grpc.unary_unary_rpc_method_handler(
          servicer.Create,
          request_deserializer=store__pb2.CreateRequest.FromString,
          response_serializer=store__pb2.CreateResponse.SerializeToString,
      ),
      'Delete': grpc.unary_unary_rpc_method_handler(
          servicer.Delete,
          request_deserializer=store__pb2.DeleteRequest.FromString,
          response_serializer=store__pb2.DeleteResponse.SerializeToString,
      ),
      'BulkGetItemsByID': grpc.unary_unary_rpc_method_handler(
          servicer.BulkGetItemsByID,
          request_deserializer=store__pb2.BulkGetItemsByIDRequest.FromString,
          response_serializer=store__pb2.BulkGetItemsByIDResponse.SerializeToString,
      ),
      'BulkUpsertItems': grpc.unary_unary_rpc_method_handler(
          servicer.BulkUpsertItems,
          request_deserializer=store__pb2.BulkUpsertItemsRequest.FromString,
          response_serializer=store__pb2.BulkUpsertItemsResponse.SerializeToString,
      ),
      'BulkDeleteItemsByID': grpc.unary_unary_rpc_method_handler(
          servicer.BulkDeleteItemsByID,
          request_deserializer=store__pb2.BulkDeleteItemsByIDRequest.FromString,
          response_serializer=store__pb2.BulkDeleteItemsByIDResponse.SerializeToString,
      ),
      'ListItems': grpc.unary_stream_rpc_method_handler(
          servicer.ListItems,
          request_deserializer=store__pb2.ListItemsRequest.FromString,
          response_serializer=store__pb2.Item.SerializeToString,
      ),
      'ListItemsForBrand': grpc.unary_stream_rpc_method_handler(
          servicer.ListItemsForBrand,
          request_deserializer=store__pb2.ListItemsForBrandRequest.FromString,
          response_serializer=store__pb2.Item.SerializeToString,
      ),
      'GenerateReadToken': grpc.unary_unary_rpc_method_handler(
          servicer.GenerateReadToken,
          request_deserializer=store__pb2.GenerateReadTokenRequest.FromString,
          response_serializer=store__pb2.GenerateReadTokenResponse.SerializeToString,
      ),
  }
  generic_handler = grpc.method_handlers_generic_handler(
      'store.ProductStore', rpc_method_handlers)
  server.add_generic_rpc_handlers((generic_handler,))
