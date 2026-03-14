#!/bin/bash
# Generates a minimal Xcode project for XCUITest E2E testing.
# This project wraps the SPM-built AgentsBoard.app.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEPROJ="$PROJECT_DIR/AgentsBoardE2E.xcodeproj"

echo "Generating E2E Xcode project at $XCODEPROJ..."

mkdir -p "$XCODEPROJ"

# Generate project.pbxproj
cat > "$XCODEPROJ/project.pbxproj" << 'PBXPROJ'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		E2E001 /* AgentsBoardE2ETests.swift in Sources */ = {isa = PBXBuildFile; fileRef = E2E002; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		E2E002 /* AgentsBoardE2ETests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AgentsBoardE2ETests.swift; sourceTree = "<group>"; };
		E2E003 /* AgentsBoard.app */ = {isa = PBXFileReference; lastKnownFileType = wrapper.application; path = AgentsBoard.app; sourceTree = BUILT_PRODUCTS_DIR; };
		E2E004 /* AgentsBoardE2ETests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = AgentsBoardE2ETests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		E2E010 = {
			isa = PBXGroup;
			children = (
				E2E011 /* Tests */,
				E2E012 /* Products */,
			);
			sourceTree = "<group>";
		};
		E2E011 /* Tests */ = {
			isa = PBXGroup;
			children = (
				E2E002 /* AgentsBoardE2ETests.swift */,
			);
			name = Tests;
			path = Tests/E2ETests;
			sourceTree = SOURCE_ROOT;
		};
		E2E012 /* Products */ = {
			isa = PBXGroup;
			children = (
				E2E004 /* AgentsBoardE2ETests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		E2E020 /* AgentsBoardE2ETests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = E2E030;
			buildPhases = (
				E2E021 /* Sources */,
				E2E022 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = AgentsBoardE2ETests;
			productName = AgentsBoardE2ETests;
			productReference = E2E004;
			productType = "com.apple.product-type.bundle.ui-testing";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		E2E040 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastUpgradeCheck = 1600;
			};
			buildConfigurationList = E2E041;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
			);
			mainGroup = E2E010;
			productRefGroup = E2E012 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				E2E020 /* AgentsBoardE2ETests */,
			);
		};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		E2E021 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				E2E001 /* AgentsBoardE2ETests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXFrameworksBuildPhase section */
		E2E022 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin XCBuildConfiguration section */
		E2E050 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = AgentsBoardE2ETests;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.agentsboard.e2etests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_TARGET_NAME = "";
			};
			name = Debug;
		};
		E2E051 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = AgentsBoardE2ETests;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.agentsboard.e2etests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TEST_TARGET_NAME = "";
			};
			name = Release;
		};
		E2E052 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				SDKROOT = macosx;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		E2E053 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				SDKROOT = macosx;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		E2E030 /* Build configuration list for PBXNativeTarget "AgentsBoardE2ETests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				E2E050 /* Debug */,
				E2E051 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
		E2E041 /* Build configuration list for PBXProject "AgentsBoardE2E" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				E2E052 /* Debug */,
				E2E053 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Debug;
		};
/* End XCConfigurationList section */

	};
	rootObject = E2E040 /* Project object */;
}
PBXPROJ

# Create scheme
mkdir -p "$XCODEPROJ/xcshareddata/xcschemes"
cat > "$XCODEPROJ/xcshareddata/xcschemes/AgentsBoardE2ETests.xcscheme" << 'SCHEME'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="E2E020" BuildableName="AgentsBoardE2ETests.xctest" BlueprintName="AgentsBoardE2ETests" ReferencedContainer="container:AgentsBoardE2E.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
</Scheme>
SCHEME

echo "✔ E2E Xcode project generated at $XCODEPROJ"
