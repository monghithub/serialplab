namespace java com.serialplab.thrift
namespace go serialplab.thrift

struct User {
  1: required string id,
  2: required string name,
  3: required string email,
  4: required i64 timestamp,
}