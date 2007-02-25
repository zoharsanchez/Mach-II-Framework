<!---
License:
Copyright 2007 Mach-II Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright: Mach-II Corporation
$Id$

Created version: 1.5.0
Updated version: 1.5.0
--->
<cfcomponent 
	displayname="SubroutineManager"
	extends="MachII.framework.CommandLoaderBase"
	output="false"
	hint="Manages registered SubroutineHandlers for the framework.">
	
	<!---
	PROPERTIES
	--->
	<cfset variables.appManager = "" />
	<cfset variables.handlers = StructNew() />
	<cfset variables.parentSubrountineManager = "" />
	<!--- temps --->
	<cfset variables.listenerMgr = "" />
	<cfset variables.filterMgr = "" />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="SubroutineManager" output="false"
		hint="Initialization function called by the framework.">
		<cfargument name="configXML" type="string" required="true" />
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfargument name="parentSubroutineManager" type="any" required="false" default=""
			hint="Optional argument for a parent subroutine manager. If there isn't one default to empty string." />
		
		<cfset var commandNodes = "" />
		<cfset var commandNode = "" />
		<cfset var eventNodes = "" />
		<cfset var subroutineHandler = "" />
		<cfset var eventAccess = "" />
		<cfset var subroutineName = "" />
		<cfset var command = "" />
		<cfset var i = 0 />
		<cfset var j = 0 />
		
		<cfset setAppManager(arguments.appManager) />
		
		<cfif isObject(arguments.parentSubroutineManager)>
			<cfset setParent(arguments.parentSubroutineManager) />
		</cfif>
		
		<!--- Set temps. --->
		<cfset variables.listenerMgr = getAppManager().getListenerManager() />
		<cfset variables.filterMgr = getAppManager().getFilterManager() />

		<cfset eventNodes = XMLSearch(configXML,"//subroutines/subroutine") />
		<cfloop from="1" to="#ArrayLen(eventNodes)#" index="i">
			<cfset subroutineName = eventNodes[i].xmlAttributes['name'] />
			
			<cfset subroutineHandler = CreateObject('component', 'MachII.framework.SubroutineHandler') />
			<cfset subroutineHandler.init() />
	  
			<cfloop from="1" to="#ArrayLen(eventNodes[i].XMLChildren)#" index="j">
			    <cfset commandNode = eventNodes[i].XMLChildren[j] />
				<cfset command = createCommand(commandNode) />
				<cfset subroutineHandler.addCommand(command) />
			</cfloop>
			
			<cfset addSubroutineHandler(subroutineName, subroutineHandler) />
		</cfloop>
		
		<!--- Clear temps. --->
		<cfset variables.listenerMgr = "" />
		<cfset variables.filterMgr = "" />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="configure" access="public" returntype="void"
		hint="Configures each of the registered SubroutineHandlers/Subroutines.">
		<!--- DO NOTHING --->
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="addSubroutineHandler" access="public" returntype="void" output="false"
		hint="Registers an SubroutineHandler by name.">
		<cfargument name="subroutineName" type="string" required="true" />
		<cfargument name="subroutineHandler" type="MachII.framework.SubroutineHandler" required="true" />
		
		<cfif isSubroutineDefined(arguments.subroutineName)>
			<cfthrow type="MachII.framework.SubroutineHandlerAlreadyDefined"
				message="An SubroutineHandler with name '#arguments.subroutineName#' is already registered." />
		<cfelse>
			<cfset variables.handlers[arguments.subroutineName] = arguments.subroutineHandler />
		</cfif>
	</cffunction>
	
	<cffunction name="getSubroutineHandler" access="public" returntype="MachII.framework.SubroutineHandler"
		hint="Returns the SubroutineHandler for the named Subroutine.">
		<cfargument name="subroutineName" type="string" required="true"
			hint="The name of the Subroutine to handle." />
		
		<cfif isSubroutineDefined(arguments.subroutineName)>
			<cfreturn variables.handlers[arguments.subroutineName] />
		<cfelseif isObject(getParent()) AND getParent().isSubroutineDefined(arguments.subroutineName)>
			<cfreturn getParent().getSubroutineHandler(arguments.subroutineName) />
		<cfelse>
			<cfthrow type="MachII.framework.SubroutineHandlerNotDefined" 
				message="SubroutineHandler for subroutine '#arguments.subroutineName#' is not defined." />
		</cfif>
	</cffunction>
	
	<cffunction name="isSubroutineDefined" access="public" returntype="boolean" output="false"
		hint="Returns true if an SubroutineHandler for the named Subroutine is defined; otherwise false.">
		<cfargument name="subroutineName" type="string" required="true"
			hint="The name of the Subroutine to handle." />
		<cfreturn StructKeyExists(variables.handlers, arguments.subroutineName) />
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setAppManager" access="public" returntype="void" output="false">
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfset variables.appManager = arguments.appManager />
	</cffunction>
	<cffunction name="getAppManager" access="public" returntype="MachII.framework.AppManager" output="false">
		<cfreturn variables.appManager />
	</cffunction>
	<cffunction name="setParent" access="public" returntype="void" output="false"
		hint="Returns the parent SubroutineManager instance this FilterManager belongs to.">
		<cfargument name="parentSubroutineManager" type="MachII.framework.SubroutineManager" required="true" />
		<cfset variables.parentSubroutineManager = arguments.parentSubroutineManager />
	</cffunction>
	<cffunction name="getParent" access="public" returntype="any" output="false"
		hint="Sets the parent SubroutineManager instance this FilterManager belongs to. It will return empty string if no parent is defined.">
		<cfreturn variables.parentSubroutineManager />
	</cffunction>
	
</cfcomponent>