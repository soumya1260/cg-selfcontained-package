def Tag = ""
pipeline {
    agent {
        docker {
            // Docker image to use for the entire run
            image 'registry.cigna.com/cornerstone/gbs-dotnet-sdk'
            // Agent label to run docker containers on
            label 'windows-build-servers'
        }
    }
    options {
        ansiColor('xterm')
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '1', numToKeepStr: '5')
    }

        environment {
        ext_name = 'gbs-fcts-lpi-calc'
        ext_project_name = 'LatePayment'
    }

    stages {
            stage("Run Tag Job") {
		when {
                anyOf {
                    branch 'main'
                }
            }
            steps {
		   script{
			   repo_url = scm.getUserRemoteConfigs()[0].getUrl()
                git_repo = repo_url.tokenize('/')[3].split("\\.")[0]
                Tag = sh(script:"git tag", returnStdout:true)
			   echo "Tag:${Tag}"
                if (Tag == "" || Tag == "0" || Tag.equals(0)){
                //version='1.0.0'
                Version=powershell(script:'(Get-Content versions.json | ConvertFrom-Json).Version', returnStdout:true).trim()
                release="${Version}.1-${git_repo}"
				echo "tag name: ${release}"
				withCredentials([usernamePassword(credentialsId: 'SVTFeeDevOpsGitHub_Credential',
							     passwordVariable: 'GITHUB_PASS', usernameVariable: 'GITHUB_ID')]) {
					sh(script:"git config --global http.sslVerify false", returnStatus:true)
						sh(script:"git remote set-url origin https://${GITHUB_ID}:${GITHUB_PASS}@github.sys.cigna.com/cigna/${git_repo}.git", returnStatus:true)
						sh(script:"git config --global user.email \"ctst-scm@cigna.com\"", returnStatus:true)
  						sh(script:"git config --global user.name \"gbs\"",returnStatus:true)
						sh(script:"git tag -a \"${release}\" -m \"tag version ${release}\"", returnStatus:true)
						Tag1 = sh(script:"git tag", returnStatus:true)
				echo "Tag:${Tag1}"
        				sh(script:"git push origin --tags", returnStatus:true)
        			}
                }
                else{
			tag_commit=sh(script:"git rev-list --tags --max-count=1",returnStdout:true).trim()
			branch_commit=sh(script:"git rev-parse HEAD",returnStdout:true).trim()
			echo "compare: ${tag_commit} ${branch_commit}"
			if(tag_commit != branch_commit){
				old_tag = sh(script:"git describe --tags `git rev-list --tags --max-count=1`",returnStdout:true).trim()
				echo "old tag: ${old_tag}"
				//release=old_tag.split("\\)_")[1]
				release=old_tag.tokenize('-')[0]
				Version=powershell(script:'(Get-Content versions.json | ConvertFrom-Json).Version', returnStdout:true).trim()
			echo "version: $Version"
			echo "release: ${release}"
                    ary1 = release.tokenize('.')
			echo "array: ${ary1}"
			F1=ary1[0]
                    	F2=ary1[1]
			F3=ary1[2]
                    	F4=ary1[3] as Integer
			echo "values: ${F1} ${F2} ${F3} ${F4}"
			git_tag_version="${F1}.${F2}.${F3}"
			echo "git tag version: ${git_tag_version}"
                    	if (git_tag_version == Version){
				echo "F4: ${F4}"
                   		F4=F4 + 1
				echo "F4: ${F4}"
                    	}
                    	else{
                        	F4 = 1
				echo "F4: ${F4}"
                    	}
                    	new_version="${Version}.${F4}"
                    	echo "new_version: ${new_version}"
			release="${new_version}-${git_repo}"
					echo "${release}"
					withCredentials([usernamePassword(credentialsId: 'SVTFeeDevOpsGitHub_Credential',
							     passwordVariable: 'GITHUB_PASS', usernameVariable: 'GITHUB_ID')]) {
						sh(script:"git config --global http.sslVerify false", returnStatus:true)
    	    				//sh(script:"git remote set-url origin https://${GITHUB_ID}:${GITHUB_PASS}@github.sys.cigna.com/cigna/${git_repo}.git", returnStatus:true)
						sh(script:"git remote set-url origin https://${GITHUB_ID}:${GITHUB_PASS}@github.sys.cigna.com/cigna/${git_repo}.git", returnStatus:true)
						sh(script:"git config --global user.email \"ctst-scm@cigna.com\"", returnStatus:true)
  						sh(script:"git config --global user.name \"gbs\"",returnStatus:true)
						sh(script:"git tag -a \"${release}\" -m \"tag version ${release}\"", returnStatus:true)
						Tag1 = sh(script:"git tag",,returnStdout:true).trim()
				echo "Tag:${Tag1}"
        				sh(script:"git push origin --tags", returnStatus:true)
					}
			}
		   }
		   }
            }
        }
        stage("Run DotNet Build") {
            steps {
                pwsh """
                    \$ErrorActionPreference = "Stop"
                    Write-Host ""
                    Write-Host "[INFO] Build Dotnet code..."
                    git tag
                    dotnet build
                """
            }
        }
        stage("Run DotNet Test") {
            steps {
                //TODO: Test are broken. Needs to be fixed.
                pwsh """
                    \$ErrorActionPreference = "Stop"
                    Write-Host ""
                    Write-Host "[INFO] Test Dotnet code..."
                    #dotnet test --no-build
                """
            }
        }
        stage("Run DotNet Publish") {
            steps {
                pwsh """
                    \$ErrorActionPreference = "Stop"
                    Write-Host ""
                    Write-Host "[INFO] Publish Dotnet code..."
                    dotnet publish -c Release -o out
                    dotnet publish -c Release -r win-x64 --self-contained -o self_contained_out
                """
            }
        }
        stage("Run DotNet Package") {
            steps {
                pwsh """
                    \$ErrorActionPreference = "Stop"
                    Write-Host ""
                    # Get user supplied version from versions.json and environment variables
                    \$DefaultVersion = "\$(git describe --tags)"
                   Write-Host "[INFO] Automatic Version Number: \$DefaultVersion"

                    Write-Host "[INFO] Pack NuGet Artifact..."
                    dotnet pack --output nupkgs /p:Version=\$DefaultVersion
                """
            }
        }
        stage("Run DotNet Self-Contained Package") {
            steps {
                pwsh """
                    \$ErrorActionPreference = "Stop"
                    Write-Host ""
                    \$DefaultVersion = "\$(git describe --tags)"
                    Write-Host "[INFO] Automatic Version Number for Self-Contained Package: \$DefaultVersion"

                    Write-Host "[INFO] Pack NuGet Artifact Self-Contained..."
                    \$xmldoc = [xml](Get-Content misc\\"\$env:ext_project_name"SC.csproj.template)
                    \$xmldoc.Project.PropertyGroup.PackageVersion = "\$DefaultVersion"
                    \$xmldoc.Save("self_contained_out/'\$env:ext_project_name'SC.csproj")

                    Set-Location self_contained_out
                    dotnet pack --output ..\\nupkgs /p:Version=\$DefaultVersion
                    Set-Location ..
                """
            }
        }
        stage("Run DotNet Push to Artifactory") {
            when {
                anyOf {
                    branch 'main'; branch 'develop'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'gbs-artifactory-id',
                    passwordVariable: 'deployerCred',
                    usernameVariable: 'deployerId')]) {
                    // There are various ways for invoking the use of multiple containers. Using  mounts the jenkins "$WORKSPACE"
                    // to the container
                    pwsh """
                        \$ErrorActionPreference = "Stop"
                        Write-Host ""
                        Write-Host "[INFO] Publish NuGet Artifact..."
                        \$ArtifactoryDeployLocation = "https://cigna.jfrog.io/artifactory/api/nuget/v3/cigna-nuget-lower/Cigna/GBS/Cornerstone/Facets/\$env:ext_name/"
                        dotnet nuget push "nupkgs\\*.nupkg" --api-key "${deployerId}:${deployerCred}" --source "\$ArtifactoryDeployLocation" --skip-duplicate
                    """
                }
            }
        }
    }
}