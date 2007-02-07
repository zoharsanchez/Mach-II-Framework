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
Author: Peter J. Farrell (peter@mach-ii.com)
$Id$

Created version: 1.5.0
Updated version: 1.5.0

Notes:
--->
<cfcomponent 
	displayname="RequestManager"
	output="false"
	hint="Manages request functionality for the framework.">

	<!---
	PROPERTIES
	--->
	<cfset variables.appManager = "" />
	<cfset variables.defaultUrlBase = "" />
	<cfset variables.eventParameter = "" />
	<cfset variables.parseSes = "" />
	<cfset variables.queryStringDelimiter = "" />
	<cfset variables.seriesDelimiter ="" />
	<cfset variables.pairDelimiter = "" />

	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="RequestManager" output="false"
		hint="Initializes the manager.">
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		
		<cfset setAppManager(arguments.appManager) />
		
		<cfreturn this />
	</cffunction>

	<cffunction name="configure" access="public" returntype="void" output="false"
		hint="Configures nothing.">
		
		<cfset var urlDelimiters = getPropertyManager().getProperty("urlDelimiters") />	
			
		<!--- Setup defaults --->
		<cfset setDefaultUrlBase(getPropertyManager().getProperty("urlBase")) />
		<cfset setEventParameter(getPropertyManager().getProperty("eventParameter")) />
		<cfset setParseSES(getPropertyManager().getProperty("urlParseSES")) />
		<cfset setQueryStringDelimiter(ListGetAt(urlDelimiters, 1)) />
		<cfset setSeriesDelimiter(ListGetAt(urlDelimiters, 2)) />
		<cfset setPairDelimiter(ListGetAt(urlDelimiters, 3)) />
	</cffunction>

	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="buildUrl" access="public" returntype="string" output="false"
		hint="Builds a framework specific url.">
		<cfargument name="eventName" type="string" required="true"
			hint="Name of the event to build the url with." />
		<cfargument name="urlParameters" type="any" required="false" default=""
			hint="Name/value pairs (urlArg1=value1,urlArg2=value2) to build the url with or a struct of data." />
		<cfargument name="urlBase" type="string" required="false" default=""
			hint="Base of the url. Defaults to index.cfm." />
		
		<cfset var builtUrl = "" />
		<cfset var params = parseBuildUrlParameters(arguments.urlParameters) />
		<cfset var i = "" />
		
		<!--- Append the base url --->
		<cfif NOT Len(arguments.urlBase)>
			<cfset builtUrl = getDefaultUrlBase() />
		<cfelse>
			<cfset builtUrl = arguments.urlBase />
		</cfif>

		<!--- Attach the event name if defined --->
		<cfif Len(arguments.eventName)>
			<cfset builtUrl = builtUrl & getQueryStringDelimiter() & getEventParameter() & getPairDelimiter() & arguments.eventName />
		</cfif>
		
		<!--- Attach each additional arguments if it exists and is a simple value --->
		<cfloop collection="#params#" item="i">
			<cfif IsSimpleValue(params[i])>
				<cfset builtUrl = builtUrl & getSeriesDelimiter() & i & getPairDelimiter() & URLEncodedFormat(params[i]) />
			</cfif>
		</cfloop>
		
		<cfreturn builtUrl />
	</cffunction>
	
	<cffunction name="parseSesParameters" access="public" returntype="struct" output="false"
		hint="Parse SES parameters.">
		<cfset var pathInfo = cgi.PATH_INFO />
		<cfset var names = "" />
		<cfset var i = "" />
		<cfset var value = "" />
		<cfset var params = StructNew() />

		<!--- Parse SES if necessary --->
		<cfif getParseSes() AND Len(pathInfo)>
			<cfset pathInfo = Right(pathInfo, Len(pathInfo) -1) />
			
			<cfset names = ListToArray(pathInfo, getUrlSeriesDelimiter()) />
			
			<cfif getSeriesDelimiter() EQ getPairDelimiter()>
				<cfloop from="1" to="#ArrayLen(names)#" index="i" step="2">
					<cfset value = "" />
					<cfif i + 1 LT ArrayLen(names)>
						<cfset value = names[i+1] />
					</cfif>
					<cfset params[names[i]] = value />
				</cfloop>
			<cfelse>
				<cfloop from="1" to="#ArrayLen(names)#" index="i">
					<cfset value = "" />
					<cfif ArrayLen(names[i]) EQ 2>
						<cfset value = ListGetAt(names[i], 2, getPairDelimiter()) />
					</cfif>
					<cfset params[ListGetAt(names[i], 1, getPairDelimiter())] =  value />
				</cfloop>
			</cfif>
		</cfif>
		
		<cfreturn params />
	</cffunction>

	<!---
	PROTECTED FUNCTIONS
	--->
	<cffunction name="parseBuildUrlParameters" access="private" returntype="struct" output="false"
		hint="Parses the build url parameters into a useable form.">
		<cfargument name="urlParameters" type="any" required="true"
			hint="Takes string of name/value pairs or a struct.">
		
		<cfset var params = StructNew() />
		<cfset var i = "" />
		
		<cfif NOT IsStruct(arguments.urlParameters)>
			<cfloop list="#arguments.urlParameters#" index="i" delimiters=",">
				<cfset params[ListFirst(i, "=")] = ListLast(i, "=") />
			</cfloop>
		<cfelse>
			<cfset params = arguments.urlParameters />
		</cfif>
		
		<cfreturn params />
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setAppManager" access="private" returntype="void" output="false">
		<cfargument name="appManager" type="MachII.framework.AppManager" required="true" />
		<cfset variables.appManager = arguments.appManager />
	</cffunction>
	<cffunction name="getAppManager" access="private" returntype="MachII.framework.AppManager" output="false">
		<cfreturn variables.appManager />
	</cffunction>
	
	<cffunction name="getPropertyManager" access="private" returntype="MachII.framework.PropertyManager" output="false">
		<cfreturn getAppManager().getPropertyManager() />
	</cffunction>
	
	<cffunction name="setEventParameter" access="private" returntype="void" output="false">
		<cfargument name="eventParameter" type="string" required="true" />
		<cfset variables.eventParameter = arguments.eventParameter />
	</cffunction>
	<cffunction name="getEventParameter" access="private" returntype="string" output="false">
		<cfreturn variables.eventParameter />
	</cffunction>
	
	<cffunction name="setParseSes" access="private" returntype="void" output="false">
		<cfargument name="parseSes" type="string" required="true" />
		<cfset variables.parseSes = arguments.parseSes />
	</cffunction>
	<cffunction name="getParseSes" access="private" returntype="string" output="false">
		<cfreturn variables.parseSes />
	</cffunction>
	
	<cffunction name="setDefaultUrlBase" access="private" returntype="void" output="false">
		<cfargument name="defaultUrlBase" type="string" required="true" />
		<cfset variables.defaultUrlBase = arguments.defaultUrlBase />
	</cffunction>
	<cffunction name="getDefaultUrlBase" access="private" returntype="string" output="false">
		<cfreturn variables.defaultUrlBase />
	</cffunction>
	
	<cffunction name="setQueryStringDelimiter" access="private" returntype="void" output="false">
		<cfargument name="queryStringDelimiter" type="string" required="true" />
		<cfset variables.queryStringDelimiter = arguments.queryStringDelimiter />
	</cffunction>
	<cffunction name="getQueryStringDelimiter" access="private" returntype="string" output="false">
		<cfreturn variables.queryStringDelimiter />
	</cffunction>

	<cffunction name="setSeriesDelimiter" access="private" returntype="void" output="false">
		<cfargument name="seriesDelimiter" type="string" required="true" />
		<cfset variables.seriesDelimiter = arguments.seriesDelimiter />
	</cffunction>
	<cffunction name="getSeriesDelimiter" access="private" returntype="string" output="false">
		<cfreturn variables.seriesDelimiter />
	</cffunction>
	
	<cffunction name="setPairDelimiter" access="private" returntype="void" output="false">
		<cfargument name="pairDelimiter" type="string" required="true" />
		<cfset variables.pairDelimiter = arguments.pairDelimiter />
	</cffunction>
	<cffunction name="getPairDelimiter" access="private" returntype="string" output="false">
		<cfreturn variables.pairDelimiter />
	</cffunction>

</cfcomponent>