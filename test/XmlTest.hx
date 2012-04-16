package ;

class XmlTest 
{
	static public function getXml()
	{
		return Xml.parse('
<?xml version="1.0" encoding="utf-8" ?>

<hx:html>

	<head offset="9.2">

		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>

		<title>haXe</title>

		<link rel="stylesheet" type="text/css" href="/css/haxe.css"/>

		<!--[if IE 6]>

		<link rel="stylesheet" type="text/css" href="/css/haxe_ie6.css"/>

		<![endif]-->

		<!--[if IE 7]>

		<link rel="stylesheet" type="text/css" href="/css/haxe_ie7.css"/>

		<![endif]-->

		

		<script type="text/javascript" src="/app.js"></script>
		<class id="class1" />
	</head>



	<body version="5">

		<div class="all">

			<div class="header">

			</div>

			<div class="site">

				<ul class="menu">

					

	

	<li><a href="/">Home</a></li>

	

	<li><a href="/download">Download</a></li>

	

	<li><a href="/doc">Documentation</a></li>

	

	<li><a href="/com">Community</a></li>

	

	<li><a href="/forum">Forum</a></li>

	

	<li><a href="/api">API</a></li>

	

	

				</ul>



				<div class="login">

					

						<h1>Login</h1>

						<p>

							You can <a href="/wiki/register">register</a> to create an account and edit the pages of the Wiki.

						</p>

						<form action="/wiki/login" method="POST" id="login">

							<span class="group"><span class="tfield">User :</span> <input name="user" class="field"/></span>

							<span class="group"><span class="tfield">Pass :</span> <input type="password" name="pass" class="field"/></span>

							<input type="hidden" name="url" value="/"/>

							<input type="submit" value="OK" class="button"/>

						</form>

					

				</div>



				<div class="search">

					<h1>Search</h1>

					<form action="/wiki/search">

						<input name="s" class="field"/>

						<input type="submit" value="OK" class="button"/>

					</form>

				</div>



				



				<div class="links">

					<h1>Options</h1>

					<ul>

						

						<li><a href="/wiki/map">Wiki Map</a></li>

						

						<li><a href="/wiki/history">Latest Changes</a></li>

						

						

						

						

	

	

					</ul>

				</div>



				<div class="langs">

					<h1>Langs</h1>

					<ul>

					

					<li><a href="/wiki/setlang?url=/;lang=en" class="on current"><img src="/img/haxe/flags/flag_en.gif" alt="en"/> <span class="name">English</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=fr" class="on"><img src="/img/haxe/flags/flag_fr.gif" alt="fr"/> <span class="name">Français</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=ru" class="on"><img src="/img/haxe/flags/flag_ru.gif" alt="ru"/> <span class="name">Pусский</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=jp" class="on"><img src="/img/haxe/flags/flag_jp.gif" alt="jp"/> <span class="name">日本語</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=nl" class="on"><img src="/img/haxe/flags/flag_nl.gif" alt="nl"/> <span class="name">Nederlands</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=de" class="on"><img src="/img/haxe/flags/flag_de.gif" alt="de"/> <span class="name">Deutsch</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=es" class="on"><img src="/img/haxe/flags/flag_es.gif" alt="es"/> <span class="name">Español</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=it" class="on"><img src="/img/haxe/flags/flag_it.gif" alt="it"/> <span class="name">Italian</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=pl" class="on"><img src="/img/haxe/flags/flag_pl.gif" alt="pl"/> <span class="name">Polski</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=pt" class="on"><img src="/img/haxe/flags/flag_pt.gif" alt="pt"/> <span class="name">Português</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=cn" class="on"><img src="/img/haxe/flags/flag_cn.gif" alt="cn"/> <span class="name">中文</span></a></li>

					

					<li><a href="/wiki/setlang?url=/;lang=ro" class="on"><img src="/img/haxe/flags/flag_ro.gif" alt="ro"/> <span class="name">Română</span></a></li>

					

					</ul>

				</div>



				<ul class="menu2">

					

	

	

				</ul>



				



				<div class="content">

					



<h1 class="title"><a href="/index">Welcome to haXe !</a></h1>


<div class="hierarchy">

	

	 <a href="/index">Welcome to haXe !</a>

	

</div>

















	

	<div class="view">

		<span class="box_intro">	<span class="img1"></span>	<span class="title">1. <a href="/doc/intro" class="intern">Discover</a></span>	<span class="desc">Discover what haXe is about, how it works and how it could be useful to you.</span></span>
<span class="box_intro">	<span class="img2"></span>	<span class="title">2. <a href="/download" class="intern">Download</a></span>	<span class="desc">Install haXe quickly with one of the automatic installers available for Windows, OSX and Linux.</span></span>
<span class="box_intro">	<span class="img3"></span>	<span class="title">3. <a href="/doc" class="intern">Learn</a></span>	<span class="desc">Access the haXe documentation and tutorials, covering many aspects of the language.</span></span>
<span class="box_intro">	<span class="img4"></span>	<span class="title">4. <a href="/com" class="intern">Get Involved</a></span>	<span class="desc">Join the haXe community, get the open source tools and libraries available for haXe.</span></span>
<span class="align_clear"></span>


	</div>

	<div class="version">

		version #9419, modified 2010-12-05 12:33:10 by <a href="/wiki/user?name=shalmoo">shalmoo</a>

	</div>









<ul class="buttons">

	

	

	

	

	

	<li><a href="/wiki/history?path=index;lang=en">history</a></li>

	<li><a href="/wiki/backlinks?path=index;lang=en">backlinks</a></li>

	

</ul>













				</div>

			</div>

			<div class="footer">

				

				Powered by <a href="http://haxe.org">haXe</a>

			</div>

		</div>

		<script src="selecthxml.js"></script>	
	</body>

</hx:html>');		
	}
}