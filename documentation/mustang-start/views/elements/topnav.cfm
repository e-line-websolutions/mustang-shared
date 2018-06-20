<cfprocessingdirective pageEncoding="utf-8" />

<cfif getSection() eq 'security' and getItem() eq 'login'>
  <cfexit />
</cfif>

<cfparam name="rc.auth.user.firstname" default="Unknown" />

<cfoutput>
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark navbar-toggleable-md fixed-top">
    <button class="navbar-toggler"
            type="button"
            data-toggle="collapse"
            data-target="##navbar-header"
            aria-controls="navbarTogglerDemo01"
            aria-expanded="false"
            aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
    <div class="collapse navbar-collapse" id="navbar-header">
      <a class="navbar-brand mr-auto" href="#buildURL(':')#"><img id="website-logo" src="/inc/img/cava-logo.min.svg" title="#i18n.translate( request.appName )#" /></a>

      <ul class="navbar-nav">
        <li class="nav-item"><img id="loading" class="pull-right" src="#request.webroot#/inc/img/loading.svg" /></li>
        <li class="nav-item active">
          <a class="nav-link" href="#buildURL(':')#"><i class="fa fa-home"></i> #i18n.translate(':main.default')#</a>
        </li>
        <li class="nav-item dropdown">
          <a href="##" class="dropdown-toggle nav-link" data-toggle="dropdown"><i class="fa fa-life-ring"></i> #i18n.translate( 'help' )#</a>
          <ul class="dropdown-menu">
            <li><a href="#buildURL(':help.faq')#"><i class="fa fa-question fa-fw"></i> #i18n.translate('help.faq')#</a></li>
            <li><a href="#buildURL(':help.contact')#"><i class="fa fa-phone fa-fw"></i> #i18n.translate('help.contact')#</a></li>
            <li><a href="#buildURL(':help.about')#" id="about-app"><i class="fa fa-info-circle fa-fw"></i> #i18n.translate('help.about')#</a></li>
          </ul>
        </li>
        <li class="nav-item dropdown">
          <a href="##" class="dropdown-toggle nav-link" data-toggle="dropdown"><i class="fa fa-user"></i> #rc.auth.user.firstname#</a>
          <ul class="dropdown-menu">
            <li><a href="#buildURL(':profile.default')#"><i class="fa fa-user fa-fw"></i> #i18n.translate('profile.default')#</a></li>
            <li class="divider"></li>
            <li><a href="#buildURL(':security.doLogout')#"><i class="fa fa-power-off fa-fw"></i> #i18n.translate('log-out')#</a></li>
          </ul>
        </li>
      </ul>
    </div>
  </nav>
</cfoutput>