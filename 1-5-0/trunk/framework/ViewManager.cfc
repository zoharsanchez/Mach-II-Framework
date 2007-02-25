<!---
License:
Copyright 2006 Mach-II Corporation

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
Author: Ben Edwards (ben@ben-edwards.com)
$Id$

Created version: 1.0.0
Updated version: 1.5.0
--->
<cfcomponent 
	displayname="ViewManager"
	output="false"
	hint="Manages registered views for the framework.">
	
	<!---
	PROPERTIES
	--->
	<cfset variables.appManager = "" />
	<cfset variables.viewPaths = StructNew() />
	<cfset variables.parentViewManager = "" />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="ViewManager" output="false"
		hint="Initialization function called by the framework.">
		<cfargument name="configXML" type="string" required="true" />
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfargument name="parentViewManager" type="any" required="false" default=""
			hint="Optional argument for a parent view manager. If there isn't one default to empty string." />
		
		<cfset var viewNodes = "" />
		<cfset var name = "" />
		<cfset var page = "" />
		<cfset var i = 0 />
		
		<cfset setAppManager(arguments.appManager) />
		
		<cfif isObject(arguments.parentViewManager)>
			<cfset setParent(arguments.parentViewManager) />
		</cfif>

		<!--- Setup up each Page-View. --->
		<cfset viewNodes = XMLSearch(configXML,"//page-views/page-view") />
		<cfloop from="1" to="#ArrayLen(viewNodes)#" index="i">
			<cfset name = viewNodes[i].xmlAttributes['name'] />
			<cfset page = viewNodes[i].xmlAttributes['page'] />
			
			<cfset variables.viewPaths[name] = page />
		</cfloop>
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="configure" access="public" returntype="void"
		hint="Prepares the manager for use.">
		<!--- DO NOTHING --->
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="getViewPath" access="public" returntype="string" output="false"
		hint="Gets the view path.">
		<cfargument name="viewName" type="string" required="true"
			hint="Name of the view path to get." />
		
		<cfif isViewDefined(arguments.viewName)>
			<cfreturn variables.viewPaths[arguments.viewName] />
		<cfelseif isObject(getParent()) AND getParent().isViewDefined(arguments.viewName)>
			<cfreturn getParent().getViewPath(arguments.viewName) />
		<cfelse>
			<cfthrow type="MachII.framework.ViewNotDefined" 
				message="View with name '#arguments.viewName#' is not defined." />
		</cfif>
	</cffunction>
	
	<cffunction name="isViewDefined" access="public" returntype="boolean" output="false"
		hint="Checks if the view is defined.">
		<cfargument name="viewName" type="string" required="true"
			hint="Name of the view to check." />
		<cfreturn StructKeyExists(variables.viewPaths, arguments.viewName) />
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
		hint="Returns the parent ViewManager instance this ViewManager belongs to.">
		<cfargument name="parentViewManager" type="MachII.framework.ViewManager" required="true" />
		<cfset variables.parentViewManager = arguments.parentViewManager />
	</cffunction>
	<cffunction name="getParent" access="public" returntype="any" output="false"
		hint="Sets the parent ViewManager instance this ViewManager belongs to. It will return empty string if no parent is defined.">
		<cfreturn variables.parentViewManager />
	</cffunction>
	
</cfcomponent>