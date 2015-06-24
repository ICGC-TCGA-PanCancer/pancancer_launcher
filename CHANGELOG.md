### Pancancer Launcher change log

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
