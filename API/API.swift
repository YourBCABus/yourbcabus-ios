// @generated
//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

public final class GetSchoolsQuery: GraphQLQuery {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    query GetSchools {
      schools {
        __typename
        id
        name
        readable
      }
    }
    """

  public let operationName: String = "GetSchools"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Query"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("schools", type: .nonNull(.list(.nonNull(.object(School.selections))))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(schools: [School]) {
      self.init(unsafeResultMap: ["__typename": "Query", "schools": schools.map { (value: School) -> ResultMap in value.resultMap }])
    }

    public var schools: [School] {
      get {
        return (resultMap["schools"] as! [ResultMap]).map { (value: ResultMap) -> School in School(unsafeResultMap: value) }
      }
      set {
        resultMap.updateValue(newValue.map { (value: School) -> ResultMap in value.resultMap }, forKey: "schools")
      }
    }

    public struct School: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["RedactedSchool"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .scalar(String.self)),
          GraphQLField("readable", type: .nonNull(.scalar(Bool.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(id: GraphQLID, name: String? = nil, readable: Bool) {
        self.init(unsafeResultMap: ["__typename": "RedactedSchool", "id": id, "name": name, "readable": readable])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return resultMap["id"]! as! GraphQLID
        }
        set {
          resultMap.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String? {
        get {
          return resultMap["name"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "name")
        }
      }

      public var readable: Bool {
        get {
          return resultMap["readable"]! as! Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "readable")
        }
      }
    }
  }
}

public final class GetBusesQuery: GraphQLQuery {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    query GetBuses($schoolID: ID!) {
      school(id: $schoolID) {
        __typename
        name
        buses {
          __typename
          id
          name
        }
      }
    }
    """

  public let operationName: String = "GetBuses"

  public var schoolID: GraphQLID

  public init(schoolID: GraphQLID) {
    self.schoolID = schoolID
  }

  public var variables: GraphQLMap? {
    return ["schoolID": schoolID]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Query"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("school", arguments: ["id": GraphQLVariable("schoolID")], type: .object(School.selections)),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(school: School? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "school": school.flatMap { (value: School) -> ResultMap in value.resultMap }])
    }

    public var school: School? {
      get {
        return (resultMap["school"] as? ResultMap).flatMap { School(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "school")
      }
    }

    public struct School: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["School"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .scalar(String.self)),
          GraphQLField("buses", type: .nonNull(.list(.nonNull(.object(Bus.selections))))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(name: String? = nil, buses: [Bus]) {
        self.init(unsafeResultMap: ["__typename": "School", "name": name, "buses": buses.map { (value: Bus) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var name: String? {
        get {
          return resultMap["name"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "name")
        }
      }

      public var buses: [Bus] {
        get {
          return (resultMap["buses"] as! [ResultMap]).map { (value: ResultMap) -> Bus in Bus(unsafeResultMap: value) }
        }
        set {
          resultMap.updateValue(newValue.map { (value: Bus) -> ResultMap in value.resultMap }, forKey: "buses")
        }
      }

      public struct Bus: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Bus"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
            GraphQLField("name", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: GraphQLID, name: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "Bus", "id": id, "name": name])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return resultMap["id"]! as! GraphQLID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String? {
          get {
            return resultMap["name"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "name")
          }
        }
      }
    }
  }
}
