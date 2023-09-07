import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var errorHandlingManager: ErrorHandlingManager
    @EnvironmentObject var authenticationManager: AuthenticationManager

    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Description:")
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Text("\"Hey, I'm \(authenticationManager.current.firstName) \(authenticationManager.current.lastName)\"")
                    .font(.body)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("From:")
                        .font(.headline)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text("\(authenticationManager.current.city ?? "n.a."), \(authenticationManager.current.countryCode ?? "n.a.")")
                        .font(.body)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Member since:")
                        .font(.headline)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(formatDate(dateString: authenticationManager.current.createdAt) ?? "n.a.")
                        .font(.body)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Email:")
                        .font(.headline)
                        .fontWeight(.light)
                    Spacer()
                    if let mailtoURL = URL(string: "mailto:\(authenticationManager.current.email)") {
                        Link(destination: mailtoURL, label: {
                            Text(authenticationManager.current.email)
                                .fontWeight(.bold)
                        })
                    }
                }

                // TODO: Add personal website
                HStack {
                    Text("Website:")
                        .font(.headline)
                        .fontWeight(.light)
                    Spacer()
                    if let websiteURL = URL(string: "https://about.embloy.com"),
                       let websiteName = getWebsiteName(from: websiteURL.absoluteString) {
                        Link(destination: websiteURL, label: {
                            Text(websiteName)
                                .fontWeight(.bold)
                        })
                    }
                }
                
                HStack {
                    Text("Account Status:")
                        .font(.headline)
                        .fontWeight(.light)
                    Spacer()
                    Text(authenticationManager.current.activityStatus == 1 ? "Active" : "Inactive")
                        .font(.body)
                        .fontWeight(.bold)
                }
            }.padding()
            
            HStack(alignment: .center, spacing: 10) {
                if let linkedInURL = authenticationManager.current.linkedinURL {
                    Button(action: {
                        openSocialMediaProfile(urlString: linkedInURL)
                    }) {
                        Image("linkedInIcon") // Replace "linkedinIcon" with the name of your LinkedIn icon image asset
                            .resizable()
                            .frame(width: 24, height: 24) // Adjust the size as needed
                            .foregroundColor(.blue)
                    }
                }
                
                if let twitterURL = authenticationManager.current.twitterURL {
                    Button(action: {
                        openSocialMediaProfile(urlString: twitterURL)
                    }) {
                        Image("twitterIcon") // Replace "twitterIcon" with the name of your Twitter icon image asset
                            .resizable()
                            .frame(width: 24, height: 24) // Adjust the size as needed
                            .foregroundColor(.blue)
                    }
                }
                
                if let facebookURL = authenticationManager.current.facebookURL {
                    Button(action: {
                        openSocialMediaProfile(urlString: facebookURL)
                    }) {
                        Image("facebookIcon") // Replace "facebookIcon" with the name of your Facebook icon image asset
                            .resizable()
                            .frame(width: 24, height: 24) // Adjust the size as needed
                            .foregroundColor(.blue)
                    }
                }
                
                if let instagramURL = authenticationManager.current.instagramURL {
                    Button(action: {
                        openSocialMediaProfile(urlString: instagramURL)
                    }) {
                        Image("instagramIcon") // Replace "instagramIcon" with the name of your Instagram icon image asset
                            .resizable()
                            .frame(width: 24, height: 24) // Adjust the size as needed
                            .foregroundColor(.orange)
                    }
                }
            }.padding()
            
            Spacer()
                .frame(maxHeight: .infinity) // Fill the remaining space
        }
        .onAppear {
            loadProfile(iteration: 0)
        }
        .padding()
    }
    func openSocialMediaProfile(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func loadProfile(iteration: Int) {
        print("Iteration \(iteration)")
        isLoading = true
        if let accessToken = authenticationManager.getAccessToken() {
            APIManager.fetchAccount(accessToken: accessToken) { result in
                switch result {
                case .success(let userResponse):
                    DispatchQueue.main.async {
                        print("case .success")
                        self.authenticationManager.current = userResponse.user
                        self.errorHandlingManager.errorMessage = nil
                        isLoading = false
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("case .failure, iteration: \(iteration)")
                        if iteration == 0 {
                            if case .authenticationError = error {
                                print("case .authenticationError")
                                // Authentication error (e.g., access token invalid)
                                // Refresh the access token and retry the request
                                self.authenticationManager.requestAccessToken() { accessTokenSuccess in
                                    if accessTokenSuccess{
                                        self.loadProfile(iteration: 1)
                                    } else {
                                        self.errorHandlingManager.errorMessage = error.localizedDescription
                                    }
                                }
                            } else {
                                print("case .else")
                                // Handle other errors
                                self.errorHandlingManager.errorMessage = error.localizedDescription
                            }
                        } else {
                            self.authenticationManager.isAuthenticated = false
                            self.errorHandlingManager.errorMessage = "Tokens expired. Log in to refresh tokens."
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func getWebsiteName(from urlString: String) -> String? {
        if let url = URL(string: urlString) {
            if let host = url.host {
                return host
            }
        }
        return nil
    }
    
    func formatDate(dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust the format according to your date string
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM yyyy" // Adjust the desired output format
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            let errorHandlingManager = ErrorHandlingManager()
            let authenticationManager = AuthenticationManager(errorHandlingManager: errorHandlingManager)
            authenticationManager.current = User.generateRandomUser()
            return ProfileView()
                .environmentObject(errorHandlingManager)
                .environmentObject(authenticationManager)
        }
    }
}
 
