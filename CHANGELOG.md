### Pancancer Launcher change log

#### 3.1.7
 - New version of Pancancer CLI: 0.0.7
 - Include `monit` for service monitoring.

#### 3.1.6
 - New version of architecture-setup: 3.1.6
 - New version pf Pancancer CLI: 0.0.6

#### 3.1.5
 - New version of Pancancer CLI: 0.0.5
 - New version of architecture-setup: 3.1.5

#### 3.1.4
 - New versions of architecture-setup (3.1.4) and Pancancer CLI (0.0.4), major changes:
   - automatically update AWS security group settings
   - Pancancer CLI will now prompt user for AWS security group name and for fleet size to pass this into container
   - Pancancer CLI can now back up old INI files and generate _n_ INI files at once.

#### 3.1.3
 - Integrate Pancancer CLI
 - New versions of architecture-setup submodules, see: [https://github.com/ICGC-TCGA-PanCancer/architecture-setup/releases/tag/3.1.3](https://github.com/ICGC-TCGA-PanCancer/architecture-setup/releases/tag/3.1.3)

#### 3.1.2
 - Fixed some bugs with fleet names.
 - New and more generic method for downloading workflows and containers.
 - Workers and launcher now use Java 8.
 - Small fixes to scripts that start launcher and start servics inside launcher.
 - Other smaller fixes.

#### 3.1.1
 - Monitoring now includes sensu checks specific for Architecture3 processes.
 - New script to launch containers has help text and proper CLI flags.
 - New short-form commands for the Architecture3 commands.
 - Fleet name is now included in all machine names on uchiwa dashboard (all nodes: sensu-server and workers).

#### 3.1.0
 - **Bindle is no longer installed.**
 - New version of architecture-setup: 3.1.0:
   - Add new params for seqware (seqware_engine and seqware_use_custom_settings)
   - Update launch_workers.sh to use youxia (used by Jenkins)
   - Update documentation
   - Move old scripts to archive/
   - New version of central-decider-client: 1.0.8
     - bug fixes
   - New version of container-host-bag: 1.0-rc.9
     - New parameters for custom seqware settings
     - don't download files to /tmp, download to ~/downloads instead.
     - Cloud ID will now be passed in from Ansible, rather than letting the arch3 components try to query it.
 - New version of architecture3 components: 1.1-beta.3 (since last release: 1.1-alpha.5)
   - Improvements to Worker stability, automatic recovery, and queue handling.
   - New lost job exporter.

#### 3.0.8
Major changes:
 - Fixes for monitoring issues related to youxia, new bashrc for worker with custom coloured prompt, other smaller fixes:
   - New version of container-host-bag: 1.0-rc.6
   - New version of monitoring-bag: 1.0-beta.7
   - New version of arch3 component: 1.1-alpha.5
 - Bindle is present in the container, but is not supported (it will be removed completely in the next release). Please use the Youxia Deployer + arch3 components to deploy and manager worker nodes.

#### 3.0.7
Major changes:
 - New version of container-host-bag: 1.0-rc.5
 - New version of arch3 component: 1.1-alpha.4

Details:
 - Changes to startup scripts - enhancements for E2E testing with Jenkins
 - Changes to arch3 config - use INI format instead of JSON format
 - Include pancancer_launcher version in shell prompt
 - Small fix to ansible play that configures database schema


#### 3.0.6
Changes in architecture-setup 3.0.6:
 - New version of central-decider-client: 1.0.7, new template file.
 - New version of container-host-bag (1.0.rc-4) contains fix for issue related to workflow deployment.

#### 3.0.5
New changes in architecture-setup 3.0.5 are:
  - New version of Bindle: 2.0.3
  - Update starter script to expose port 5672 for RabbitMQ

#### 3.0.4
  - New version of the pancancer Architecture3 jar allows workers to run in "--endless" mode.
  - A few small fixes in scripts and playbooks.

#### 3.0.3
  - Monitoring! The sensu server is now installed by default in the pancancer_launcher container, and will be deployed to all worker nodes.

#### 3.0.2
  - Improved functionality to copy GNOS keys to workers and other smaller fixes.
