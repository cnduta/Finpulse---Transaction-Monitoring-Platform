using './main.bicep'

param projectName = 'finpulse'
param environment = 'dev'
param location = 'uksouth'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
