<?xml version="1.0" encoding="ISO-8859-1" ?>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="com.google.inject.Injector" %>
<%@ page import="net.socialgamer.cah.Constants.DisconnectReason" %>
<%@ page import="net.socialgamer.cah.Constants.LongPollEvent" %>
<%@ page import="net.socialgamer.cah.Constants.LongPollResponse" %>
<%@ page import="net.socialgamer.cah.Constants.ReturnableData" %>
<%@ page import="net.socialgamer.cah.StartupUtils" %>
<%@ page import="net.socialgamer.cah.data.ConnectedUsers" %>
<%@ page import="net.socialgamer.cah.data.QueuedMessage" %>
<%@ page import="net.socialgamer.cah.data.QueuedMessage.MessageType" %>
<%@ page import="net.socialgamer.cah.data.User" %>
<%@ page import="java.util.Collection" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>

<%
String remoteAddr = request.getRemoteAddr();
// TODO better access control than hard-coding IP addresses.
if (!(remoteAddr.equals("0:0:0:0:0:0:0:1") || remoteAddr.equals("127.0.0.1") ||
    remoteAddr.equals("98.248.33.90"))) {
  response.sendError(403, "Access is restricted to known hosts");
  return;
}

ServletContext servletContext = pageContext.getServletContext();
Injector injector = (Injector) servletContext.getAttribute(StartupUtils.INJECTOR);

ConnectedUsers connectedUsers = injector.getInstance(ConnectedUsers.class);

// process verbose toggle
String verboseParam = request.getParameter("verbose");
if (verboseParam != null) {
  if (verboseParam.equals("on")) {
    servletContext.setAttribute(StartupUtils.VERBOSE_DEBUG, Boolean.TRUE);
  } else {
    servletContext.setAttribute(StartupUtils.VERBOSE_DEBUG, Boolean.FALSE);
  }
  response.sendRedirect("admin.jsp");
  return;
}

// process kick
String kickParam = request.getParameter("kick");
if (kickParam != null) {
  User user = connectedUsers.getUser(kickParam);
  if (user != null) {
    Map<ReturnableData, Object> data = new HashMap<ReturnableData, Object>();
    data.put(LongPollResponse.EVENT, LongPollEvent.KICKED.toString());
    QueuedMessage qm = new QueuedMessage(MessageType.KICKED, data);
    user.enqueueMessage(qm);

    connectedUsers.removeUser(user, DisconnectReason.KICKED);
  }
  response.sendRedirect("admin.jsp");
  return;
}

%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>CAH - Admin</title>
<style type="text/css" media="screen">
table, th, td {
  border: 1px solid black;
}

th, td {
  padding: 5px;
}
</style>
</head>
<body>

<p>
  Server up since
  <%
  Date startedDate = (Date) servletContext.getAttribute(StartupUtils.DATE_NAME);
  long uptime = System.currentTimeMillis() - startedDate.getTime();
  uptime /= 1000L;
  long seconds = uptime % 60L;
  long minutes = (uptime / 60L) % 60L;
  long hours = (uptime / 60L / 60L) % 24L;
  long days = (uptime / 60L / 60L / 24L);
  out.print(String.format("%s (%d hours, %02d:%02d:%02d)",
      startedDate.toString(), days, hours, minutes, seconds));
  %>
</p>

<table>
  <tr>
    <th>Stat</th>
    <th>MiB</th>
  </tr>
  <tr>  
    <td>In Use</td>
    <td><% out.print((Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory())
        / 1024L / 1024L); %></td>
  </tr>
  <tr>  
    <td>Free</td>
    <td><% out.print(Runtime.getRuntime().freeMemory() / 1024L / 1024L); %></td>
  </tr>
  <tr>  
    <td>JVM Allocated</td>
    <td><% out.print(Runtime.getRuntime().totalMemory() / 1024L / 1024L); %></td>
  </tr>
  <tr>  
    <td>JVM Max</td>
    <td><% out.print(Runtime.getRuntime().maxMemory() / 1024L / 1024L); %></td>
  </tr>
</table>
<br/>
<table>
  <tr>
    <th>Username</th>
    <th>Host</th>
    <th>Actions</th>
  </tr>
  <%
  Collection<User> users = connectedUsers.getUsers();
  for (User u : users) {
    // TODO have a ban system. would need to store them somewhere.
	  %>
	  <tr>
	    <td><% out.print(u.getNickname()); %></td>
	    <td><% out.print(u.getHostName()); %></td>
	    <td><a href="?kick=<% out.print(u.getNickname()); %>">Kick</a></td>
	  </tr>
	  <%
  }
  %>
</table>

<%
Boolean verboseDebugObj = (Boolean) servletContext.getAttribute(StartupUtils.VERBOSE_DEBUG); 
boolean verboseDebug = verboseDebugObj != null ? verboseDebugObj.booleanValue() : false;
%>
<p>
  Verbose logging is currently <strong><% out.print(verboseDebug ? "ON" : "OFF"); %></strong>.
  <a href="?verbose=on">Turn on.</a> <a href="?verbose=off">Turn off.</a>
</p>

</body>
</html>
