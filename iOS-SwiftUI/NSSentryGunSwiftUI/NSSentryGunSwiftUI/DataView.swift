import SwiftUI

struct DataView: View {

    let descriptionText: String
    let degreesText: String
    let connectionText: String
    let isConnected: Bool?

    let padding: CGFloat = 32

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text(connectionText)
                    .font(.system(.callout))
                    .foregroundColor(isConnected == true ? .green : .red)
                Spacer()
            }
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Text(descriptionText)
                    .font(.system(.largeTitle))
                Text(degreesText)
                    .font(.system(.title))
            }
        }.padding(padding)
    }
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
        DataView(descriptionText: "Description",
                 degreesText: "Degrees",
                 connectionText: "Connection",
                 isConnected: true)
    }
}
