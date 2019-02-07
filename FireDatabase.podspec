#  Validate Podspec by running 'pod spec lint FireDatabase.podspec'
#  Podspec attributes : http://docs.cocoapods.org/specification.html
#  Podspecs examples : https://github.com/CocoaPods/Specs/

Pod::Spec.new do |s|

    s.name         = "FireDatabase"
    s.version      = "1.0.0"
    s.summary      = "Firebase FireDatabase helpful extensions + ReactiveSwift"
    s.description  = <<-DESC
						Working with Firebase Database become a whole lot easier with this framework !
						References, automatic data mapping and reactive extensions are provided to help you focus on builduing your app.
                        DESC
    s.homepage     = "https://github.com/iDonJose/FireDatabase"
    s.source       = { :git => "https://github.com/iDonJose/FireDatabase.git", :tag => "#{s.version}" }

    s.license      = { :type => "Apache 2.0", :file => "LICENSE" }

    s.author       = { "iDonJose" => "donor.develop@gmail.com" }

    s.ios.deployment_target = "8.0"

	s.static_framework = true


	s.subspec 'Core' do |core|

		s.frameworks = "Foundation"

		s.dependency "SwiftXtend", "~> 1.1"
		s.dependency "FirebaseDatabase", "~> 5.0.3"
		
		core.source_files  = "Sources/**/*.{h,swift}"
	end

	s.subspec 'ReactiveSwift' do |reactiveSwift|
		reactiveSwift.dependency "FireDatabase/Core"
		reactiveSwift.dependency "ReactiveSwift", "~> 4.0"
		reactiveSwift.xcconfig = { "OTHER_SWIFT_FLAGS" => "-D USE_REACTIVESWIFT" }
	end

	s.default_subspecs = 'Core', 'ReactiveSwift'

end
