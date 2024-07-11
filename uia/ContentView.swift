import SwiftUI
import RealityKit
import Combine

struct USDView: UIViewRepresentable {
    var fileName: String
    @Binding var currentAnimation: String
    @State private var cancellables: Set<AnyCancellable> = []

    class Coordinator {
        var waveModel: Entity?
        var jumpUpModel: Entity?
        var jumpFloatModel: Entity?
        var jumpDownModel: Entity?
        var anchor: AnchorEntity?
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Load the usdz file as an Entity from the app bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "usda") else {
            print("Failed to find USD file in the bundle")
            return arView
        }

        do {
            let characterAnimationSceneEntity = try Entity.load(contentsOf: fileURL)

            // Ensure the entity has the correct name
            context.coordinator.waveModel = characterAnimationSceneEntity.findEntity(named: "wave_model")
            context.coordinator.jumpUpModel = characterAnimationSceneEntity.findEntity(named: "jump_up_model")
            context.coordinator.jumpFloatModel = characterAnimationSceneEntity.findEntity(named: "jump_float_model")
            context.coordinator.jumpDownModel = characterAnimationSceneEntity.findEntity(named: "jump_down_model")

            // Create an anchor and store it in the coordinator
            context.coordinator.anchor = AnchorEntity(world: .zero)
            arView.scene.anchors.append(context.coordinator.anchor!)

        } catch {
            print("Failed to load USD file: \(error)")
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        guard let anchor = context.coordinator.anchor else { return }

        // Remove all children from the anchor
        anchor.children.removeAll()

        // Play the selected animation
        switch currentAnimation {
        case "wave":
            if let waveModel = context.coordinator.waveModel,
               let waveAnimationResource = waveModel.availableAnimations.first {
                anchor.addChild(waveModel)
                waveModel.playAnimation(waveAnimationResource.repeat())
            }
        case "jump":
            if let jumpUpModel = context.coordinator.jumpUpModel,
               let jumpFloatModel = context.coordinator.jumpFloatModel,
               let jumpDownModel = context.coordinator.jumpDownModel,
               let jumpUpAnimationResource = jumpUpModel.availableAnimations.first,
               let jumpFloatAnimationResource = jumpFloatModel.availableAnimations.first,
               let jumpDownAnimationResource = jumpDownModel.availableAnimations.first {
                let jumpAnimation = try? AnimationResource.sequence(with: [jumpUpAnimationResource, jumpFloatAnimationResource, jumpDownAnimationResource])
                if let jumpAnimation = jumpAnimation {
                    anchor.addChild(jumpUpModel)
                    anchor.addChild(jumpFloatModel)
                    anchor.addChild(jumpDownModel)
                    jumpUpModel.playAnimation(jumpAnimation.repeat())
                    jumpFloatModel.playAnimation(jumpAnimation.repeat())
                    jumpDownModel.playAnimation(jumpAnimation.repeat())
                }
            }
        default:
            break
        }
    }
}

struct ContentView: View {
    @State private var currentAnimation: String = ""

    var body: some View {
        VStack {
            USDView(fileName: "CharacterAnimations", currentAnimation: $currentAnimation)
                .edgesIgnoringSafeArea(.all)

            HStack {
                Button("Wave") {
                    currentAnimation = "wave"
                }
                .padding()

                Button("Jump") {
                    currentAnimation = "jump"
                }
                .padding()

                Button("Stop") {
                    currentAnimation = ""
                }
                .padding()
            }
        }
    }
}
