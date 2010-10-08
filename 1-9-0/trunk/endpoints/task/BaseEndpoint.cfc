<!---

    Mach-II - A framework for object oriented MVC web applications in CFML
    Copyright (C) 2003-2010 GreatBizTools, LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.

	As a special exception, the copyright holders of this library give you
	permission to link this library with independent modules to produce an
	executable, regardless of the license terms of these independent
	modules, and to copy and distribute the resultant executable under
	the terms of your choice, provided that you also meet, for each linked
	independent module, the terms and conditions of the license of that
	module.  An independent module is a module which is not derived from
	or based on this library and communicates with Mach-II solely through
	the public interfaces* (see definition below). If you modify this library,
	but you may extend this exception to your version of the library,
	but you are not obligated to do so. If you do not wish to do so,
	delete this exception statement from your version.


	* An independent module is a module which not derived from or based on
	this library with the exception of independent module components that
	extend certain Mach-II public interfaces (see README for list of public
	interfaces).

Author: Peter J. Farrell (peter@mach-ii.com)
$Id$

Created version: 1.9.0

Notes:

Configuration Notes:

<endpoints>
	<endpoint name="scheduledTasks" type="MachII.endpoints.schedule.BaseEndpoint">
		<parameters>
		</parameters>
	</endpoint>
</endpoints>

--->
<cfcomponent
	displayname="ScheduledTaskEndpoint"
	extends="MachII.endpoints.AbstractEndpoint"
	output="false"
	hint="Base endpoint for all scheduled task endpoints to be exposed directly by Mach-II.">

	<!---
	CONSTANTS
	--->
	<!--- Constants for the annotations we allow in ScheduledTask sub-classes --->
	<cfset variables.ANNOTATION_TASK_BASE = "TASK" />
	<cfset variables.ANNOTATION_TASK_INTERVAL = variables.ANNOTATION_TASK_BASE & ":INTERVAL" />
	<cfset variables.ANNOTATION_TASK_STARTDATETIME = variables.ANNOTATION_TASK_BASE & ":STARTDATETIME" />
	<cfset variables.ANNOTATION_TASK_ENDDATETIME = variables.ANNOTATION_TASK_BASE & ":ENDDATETIME" />
	<cfset variables.ANNOTATION_TASK_REQUESTTIMEOUT = variables.ANNOTATION_TASK_BASE & ":REQUESTTIMEOUT" />
	<cfset variables.ANNOTATION_TASK_ALLOWCONCURRENTEXECUTIONS = variables.ANNOTATION_TASK_BASE & ":ALLOWCONCURRENTEXECUTIONS" />
	<cfset variables.ANNOTATION_TASK_RETRYONFAILURE = variables.ANNOTATION_TASK_BASE & ":RETRYONFAILURE" />

	<!---
	PROPERTIES
	--->
	<!--- Introspector looks for TASK:* annotations in child classes to find TASK-enabled methods. --->
	<cfset variables.introspector = CreateObject("component", "MachII.util.metadata.Introspector").init() />
	<cfset variables.authentication = "" />
	<cfset variables.authUsername = "" />
	<cfset variables.authPassword = "" />
	<cfset variables.adminApi = "" />
	<cfset variables.taskNamePrefix = "" />
	<cfset variables.tasks = StructNew() />

	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="configure" access="public" returntype="void" output="false"
		hint="Configures the scheduled task endpoint. Override to provide custom functionality and call super.preProcess().">
		
		<!--- Default is "{applicationName}_{endpointName}_" or "{userDefinedPrefix}_" --->
		<cfset setTaskNamePrefix(getParameter("taskNamePrefix", application.name & "_" & getParameter("name")) & "_") />
		<cfset setUrlBase(getProperty("urlBase")) />
		<cfset setAuthUsername(getParameter("authUsername")) />
		<cfset setAuthPassword(getParameter("authPassword")) />
		
		<!--- Setup additional services --->
		<cfset variables.authentication = CreateObject("component", "MachII.security.http.basic.Authentication").init(application.name & "Scheduled Tasks") />
		<cfset variables.authentication.setCredentials(buildAuthCredentials()) />
		<cfset variables.adminApi = getUtils().createAdminApiAdapter() />
		
		<!--- Setup the endpoint --->
		<cfset setupTaskMethods() />
	</cffunction>

	<!---
	PUBLIC METHODS - REQUEST
	--->
	<cffunction name="onAuthentication" access="public" returntype="void" output="false"
		hint="Authenticates the scheduled task request.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />

		<!--- All requests must be authenticated --->
		<cfif NOT variables.authentication.authenticate(getHTTPRequestData().headers)>
			<cfthrow type="MachII.endpoints.task.notAuthorized"
				message="Bad credentials." />
		</cfif>
	</cffunction>
	
	<cffunction name="handleRequest" access="public" returntype="void" output="true"
		hint="Executes the scheduled task method.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />

		<cfset var taskName = arguments.event.getArg("task") />
		
		<!--- Check for a task that accepts requests from the outside (always check variables.tasks for security reasons) --->
		<cfif StructKeyExists(variables.tasks, taskName)>
			
			<!--- TODO: Handle allow concurrent execution --->
			
			<!--- TODO: Handle retry on failure --->
			<cfinvoke method="#taskName#">
				<cfinvokeargument name="event" value="#arguments.event#" />
			</cfinvoke>
		<cfelse>
			<cfthrow type="MachII.endpoints.task.notFound"
				message="Cannot find a task named '#taskName#' in scheduled task endpoint." />
		</cfif>
	</cffunction>
	
	<cffunction name="onException" access="public" returntype="void" output="true"
		hint="Runs when an exception occurs in the endpoint.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		<cfargument name="exception" type="MachII.util.Exception" required="true"
			hint="The Exception that was thrown/caught by the endpoint request processor." />
		
		<!--- Handle notFound --->
		<cfif arguments.exception.getType() EQ "MachII.endpoints.task.notFound">
			<cfset addHTTPHeaderByStatus(404) />
			<cfset addHTTPHeaderByName("machii.endpoint.error", arguments.exception.getMessage()) />
			<cfsetting enablecfoutputonly="false" /><cfoutput>404 Not Found - #arguments.exception.getMessage()#</cfoutput><cfsetting enablecfoutputonly="true" />
		<!--- Handle cfmNotAuthorized --->
		<cfelseif arguments.exception.getType() EQ "MachII.endpoints.task.notAuthorized">
			<cfset addHTTPHeaderByStatus(401) />
			<cfset addHTTPHeaderByName("machii.endpoint.error", arguments.exception.getMessage()) />
			<cfsetting enablecfoutputonly="false" /><cfoutput>401 Not Authorized- #arguments.exception.getMessage()#</cfoutput><cfsetting enablecfoutputonly="true" />
		<!--- Default exception handling --->
		<cfelse>
			<cfset super.onException(arguments.event, arguments.exception) />
		</cfif>
	</cffunction>
	
	<cffunction name="buildEndpointUrl" access="public" returntype="string" output="false"
		hint="Builds an Url specific to this endpoint. We use query string URLs because it does not matter for scheduled tasks.">
		<cfargument name="task" type="string" required="true"
			hint="The name of the task." />
			
		<cfset var builtUrl = getUrlBase() & "?" />
		
		<cfset builtUrl = ListAppend(builtUrl, "endpoint=" & getParameter("name"), "&") />
		<cfset builtUrl = ListAppend(builtUrl, "task=" & arguments.file, "&") />
		
		<cfreturn builtUrl />
	</cffunction>
	
	<!---
	PUBLIC METHODS - UTILS
	--->
	
	<!---
	PROTECTED METHODS
	--->
	<cffunction name="setupTaskMethods" access="private" returntype="void" output="false"
		hint="Setups all task related methods by introspection the metadata. This method is recursive and looks through all the object hierarchy until the stop class.">
		<cfargument name="taskMethodMetadata" type="array" required="false"
			default="#variables.introspector.findFunctionsWithAnnotations(object:this, namespace:variables.ANNOTATION_TASK_BASE, walkTree:true, walkTreeStopClass:'MachII.endpoints.schedule.BaseEndpoint')#"
			hint="An array of metadata to discover any TASK methods in." />
		
		<!--- TODO: Parse metadata and build task struct --->
		
		<!--- Remove all task by prefix --->
		<cfset variables.adminApi.deleteTasks(getTaskNamePrefix() & "*") />
		
		<!--- TODO: Add all discovered tasks --->
	</cffunction>
	
	<cffunction name="buildAuthCredentials" access="private" returntype="struct" output="false"
		hint="Builds the authentication credentials maps for injection into the basic HTTP access authenticate module.">
		
		<cfset var credentials = StructNew() />
		
		<cfset credentials[getAuthUsername()] = Hash(getAuthPassword(), "sha") />
		
		<cfreturn credentials />
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setTaskNamePrefix" access="public" returntype="void" output="false">
		<cfargument name="taskNamePrefix" type="string" required="true" />
		<cfset variables.taskNamePrefix = arguments.taskNamePrefix />
	</cffunction>
	<cffunction name="getTaskNamePrefix" access="public" returntype="string" output="false">
		<cfreturn variables.taskNamePrefix />
	</cffunction>
	
	<cffunction name="setBasePath" access="public" returntype="void" output="false">
		<cfargument name="basePath" type="string" required="true" />
		<cfset variables.basePath = arguments.basePath />
	</cffunction>
	<cffunction name="getBasePath" access="public" returntype="string" output="false">
		<cfreturn variables.basePath />
	</cffunction>
	
	<cffunction name="setAuthUsername" access="public" returntype="void" output="false">
		<cfargument name="authUsername" type="string" required="true" />
		
		<cfif NOT Len(arguments.authUsername)>
			<!--- TODO: generate random username --->
			<cfset arguments.authUsername = "GENERATEDRANDOMUSERNAME" />
		</cfif>
		<cfset variables.authUsername = arguments.authUsername />
	</cffunction>
	<cffunction name="getAuthUsername" access="public" returntype="string" output="false">
		<cfreturn variables.authUsername />
	</cffunction>

	<cffunction name="setAuthpassword" access="public" returntype="void" output="false">
		<cfargument name="authpassword" type="string" required="true" />
		
		<cfif NOT Len(arguments.authPassword)>
			<!--- TODO: generated random passworf --->
			<cfset arguments.authPassword = "GENERATEDRANDOMUPASSWORD" />
		</cfif>
		<cfset variables.authPassword = arguments.authPassword />
	</cffunction>
	<cffunction name="getAuthpassword" access="public" returntype="string" output="false">
		<cfreturn variables.authPassword />
	</cffunction>

</cfcomponent>