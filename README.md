# FireDatabase

Working with [`Firebase Database`](https://firebase.google.com/docs/database/)  become a whole lot easier with this framework !
References, automatic data mapping and reactive extensions are provided to help you focus on builduing your app.
<p align="center">
	<a href="https://swift.org">
        <img src="https://img.shields.io/badge/Swift-4.2-orange.svg" />
    </a>
    <a>
        <img src="https://img.shields.io/badge/platform-iOS-lightgrey.svg" />
    </a>
    <a>
          <img src="https://img.shields.io/github/release/iDonJose/FireDatabase.svg" />
    </a>
    <a href="https://cocoapods.org/pods/FireDatabase">
          <img src="https://img.shields.io/cocoapods/v/FireDatabase.svg" />
    </a>
</p>


## 🎲 Playground

Jump to the included Playground to get a quick hint of what this framework can do !

![](https://github.com/iDonJose/FireDatabase/raw/master/Meta/Playground.gif)

 1. [Clone this repository.](https://github.com/idonjose/FireDatabase/archive/master.zip)
 1. Install pods with `$ pod install`
 1. Open `FireDatabase.xcworkspace`
 1. Build `FireDatabase-iOS` scheme with an iOS Simulator
 1. Open `Playground.playground`
 1. Run Playground !


## 🛠 Installation

### CocoaPods

If you are using CocoaPods as a dependency manager, add this one line to your `Podfile`:
> Don't forget to add pods 'Firebase/Core' & 'Firebase/Database' !

```ruby
pod 'FireDatabase'
pod 'Firebase/Core', '~> 5.12.0'
pod 'Firebase/Database', '~> 5.12.0'
```

And update your pods with this command:

```bash
$ pod install
```

### Manually

To add *FireDatabase* to your project manually, download the source code and place it in your project directory.


## 👋 Contributing

1. [Fork this repository.](https://github.com/idonjose/FireDatabase/fork)
1. Create a feature branch (`git checkout -b feature/myFeature`)
1. Commit the changes (`git commit -am 'Add my new feature'`)
1. Push to the branch (`git push origin feature/myFeature`)
1. Create a new Pull Request


## ✍️ Authors
*FireDatabase* was created and is still maintained by [José Donor](donor.develop@gmail.com).

## 👏 Greetings
*FireDatabase* was made possible thanks to :
- [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)

## 📃 License
*FireDatabase* is released under an Apache 2.0 license. See [License](https://github.com/idonjose/FireDatabase/blob/master/LICENSE) for more information.
