//
//  MasterView.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import Apollo

struct SchoolsListView: View {
    @State var result: Result<GraphQLResult<GetSchoolsQuery.Data>, Error>?
    
    var body: some View {
        Group {
            switch result {
            case .none:
                Text("Loading...")
            case .some(.success(let result)):
                if let data = result.data {
                    List(data.schools, id: \.id) { school in
                        VStack(alignment: .leading) {
                            Text(school.name ?? "(unnamed school)").multilineTextAlignment(.leading)
                            if !school.readable {
                                Text("Requires Authentication").foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Error")
                }
            case .some(.failure(_)):
                Text("Error")
            }
        }.onAppear {
            Network.shared.apollo.fetch(query: GetSchoolsQuery()) { result in
                self.result = result
            }
        }.navigationTitle("Schools")
    }
}
