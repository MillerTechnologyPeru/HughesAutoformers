//
//  HughesAutoformersAdvertisementRow.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import SwiftUI
import Bluetooth
import HughesAutoformers

struct HughesAutoformersAdvertisementRow: View {
    
    @EnvironmentObject
    private var store: AccessoryManager
    
    let accessory: HughesAutoformersAccessory
    
    var body: some View {
        StateView(
            accessory: accessory,
            information: store.accessoryInfo?[accessory.type]
        )
    }
}

internal extension HughesAutoformersAdvertisementRow {
    
    struct StateView: View {
        
        let accessory: HughesAutoformersAccessory
        
        let information: HughesAutoformersAccessoryInfo?
        
        var body: some View {
            HStack {
                // icon
                VStack {
                    if let information {
                        CachedAsyncImage(
                            url: URL(string: information.image),
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }, placeholder: {
                                Image(systemName: information.symbol)
                            })
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .frame(width: 40)
                
                // Text
                VStack(alignment: .leading) {
                    Text(verbatim: accessory.type.rawValue)
                        .font(.title3)
                    Text(verbatim: accessory.id)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            
        }
    }
}
/*
#if DEBUG
struct HughesAutoformersAdvertisementRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                HughesAutoformersAdvertisementRow(
                    HughesAutoformersAccessory()
                )
            }
        }
    }
}
#endif
*/
