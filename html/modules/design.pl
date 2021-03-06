%MSG = loadLang('design');

my $html;

unless ( $input{submod} ) {
	$html .= qq~<div class="contentTitle">$MSG{Autobots_Design}</div>~ unless $input{'shtl'};
	
	$html .= qq~
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="design">
	<input type="hidden" name="submod" value="new_autoBot">
	$MSG{Create_new_Autobot}: &nbsp; <input type="text" name="NewAutoBotName" maxlength="100" placeholder="$MSG{Type_a_new_NAME}" required> &nbsp; 
	<input class="blueLightButton" type="submit" value="$MSG{Create_New}">
	</form>
	
	<br><br>
	~;
	
	connected();
	my $sth1 = $dbh->prepare("SELECT idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active FROM autoBot ORDER BY autoBotName ASC");
	$sth1->execute();
	my $autoBot = $sth1->fetchall_arrayref;
	$sth1->finish;
	
	$html .= qq~
	<table cellpadding="0" cellspacing="0" class="gridTable" style="background-color: #FFFFFF;">
	<tr>
	<td class="gridTitle">$MSG{Name}</td>
	<td class="gridTitle">$MSG{Description}</td>
	<td class="gridTitle">$MSG{Deployed_Date}</td>
	<td class="gridTitle">$MSG{Deployed_by}</td>
	<td class="gridTitle">$MSG{Active}</td>
	</tr>
	~;
	
	if ( $autoBot ) {
		for my $i ( 0 .. $#{$autoBot} ) {
			my $sth = $dbh->prepare("SELECT username FROM users WHERE idUser = '$autoBot->[$i][4]'");
			$sth->execute();
			my ($userDeploy) = $sth->fetchrow_array;
			$sth->finish;
			
			my $active = '<font color="#4D4D4D">No</font>';
			if ( $autoBot->[$i][5] eq '1' ) {
				$active = qq~<font color="#008000">$MSG{Active}</font>~;
			}
			$html .= qq~<tr class="gridRowContent">
			<td class="gridContent" style="overflow: hidden; text-overflow: ellipsis"><a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$autoBot->[$i][0]">$autoBot->[$i][1]</a></td>
			<td class="gridContent" style="overflow: hidden; text-overflow: ellipsis">$autoBot->[$i][2]</td>
			<td class="gridContent">$autoBot->[$i][3]</td>
			<td class="gridContent">$userDeploy</td>
			<td class="gridContent">$active</td>
			</tr>~;
		}
	}
	
	$dbh->disconnect if ($dbh);
	$html .= qq~</table>~;
}



if ( $input{submod} eq 'new_autoBot_from_xml' ) {
	$html .= qq~<div class="contentTitle">$MSG{Create_New_from_XML}</div>~ unless $input{'shtl'};
	
	$html .= qq~<table cellpadding="0" cellspacing="0"><tr><td align="right">
	
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="design">
	<input type="hidden" name="submod" value="new_autoBot">
	$MSG{AutoBot_Name}: &nbsp; <input type="text" name="NewAutoBotName" maxlength="100" placeholder="$MSG{Type_a_new_NAME}" required> <br />
	$MSG{Enter_Autobot_ID}: &nbsp; <input type="text" name="idAutoBotManual" maxlength="40" placeholder="$MSG{Enter_new_Autobot_ID}" required>  <br />
	$MSG{Enter_XML_code}: &nbsp; <input type="text" name="xml" placeholder="$MSG{Enter_XML_Code_to_import}" required>
	<br />
	<br />
	<input class="blueLightButton" type="submit" value="$MSG{Create_New}">
	</form>
	
	</td></tr></table>~;
}



if ( $input{submod} eq 'new_autoBot' ) {
	my $newID = `../generateEncKey.pl 40`;
	if ( $input{idAutoBotManual} ) {
		$newID = $input{idAutoBotManual};
	}
	# my $newID = $input{idAutoBotManual} ? $input{idAutoBotManual} : `../generateEncKey.pl 40`;
	
	connected();
	my $sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$username'");
	$sth->execute();
	my ($myIDuser) = $sth->fetchrow_array;
	$sth->finish;
	# $dbh->disconnect if ($dbh);
	
	# connected();
	my $sth = $dbh->prepare("SELECT idAutoBot FROM autoBot WHERE idAutoBot = '$newID'");
	$sth->execute();
	my ($IDexists) = $sth->fetchrow_array;
	$sth->finish;
	# $dbh->disconnect if ($dbh);
	
	unless ( $IDexists ) {
		my $sysdate = sysdate();
		my $xml = '<AUTO><ON><VAR name="number" compare="exists"/><VAR name="sys_id" compare="exists"/><VAR name="subject" compare="eq" value=""/><VAR name="state" compare="exists"/><VAR name="type" compare="exists"/></ON></AUTO>';
		
		if ( $input{xml} ) {
			$input{xml} =~ s/\%20/ /g;
			$input{xml} =~ s/\%27/\'/g;
			$input{xml} =~ s/\%22/\"/g;
			$input{xml} =~ s/\%3B/\;/g;
			$input{xml} =~ s/\%3A/\:/g;
			$input{xml} =~ s/\%3C/\</g;
			$input{xml} =~ s/\%3E/\>/g;
			
			$input{xml} =~ s/\&gt\;/\>/g;
			$input{xml} =~ s/\&lt\;/\</g;
			$input{xml} =~ s/\&amp;/\&/g;
			$input{xml} =~ s/\&quot;/\"/g;
			$input{xml} =~ s/\&apos\;/\'/g;
			
			$xml = $input{xml};
			$xml =~ s/\>\s*\</\>\</g;
		}
		
		# $html .= qq~
		# VALUES ('$newID', '$input{NewAutoBotName}', '$sysdate', '$myIDuser', '0', <br>
		# <pre>$xml</pre>
		# ~;
		
		my $insert_string = "INSERT INTO autoBot (idAutoBot, autoBotName, deployedDate, idUserDeploy, active, autoBotXML) 
		VALUES ('$newID', '$input{NewAutoBotName}', '$sysdate', '$myIDuser', '0', ?)";
		$sth = $dbh->prepare("$insert_string");
		$sth->execute($xml);
		$sth->finish;
	}
	$dbh->disconnect if ($dbh);
	
	print "Location: index.cgi?mod=design&submod=edit_autobot&autoBotId=$newID\n\n";
}



if ( $input{submod} eq 'save_autobot_xml' ) {
	if ( $input{xml} ) {
		connected();
		my $sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$username'");
		$sth->execute();
		my ($myIDuser) = $sth->fetchrow_array;
		$sth->finish;
		
		my $sth = $dbh->prepare("SELECT * FROM autoBot WHERE idAutoBot = '$input{autoBotId}'");
		$sth->execute();
		my @ABOT = $sth->fetchrow_array;
		$sth->finish;
		
		my $insert_string = "INSERT INTO autoBotHistory (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) 
		VALUES (?, ?, ?, ?, ?, ?, ?)";
		$sth = $dbh->prepare("$insert_string");
		$sth->execute($ABOT[0], $ABOT[1], $ABOT[2], $ABOT[3], $ABOT[4], $ABOT[5], $ABOT[6]);
		$sth->finish;
		
		$input{xml} =~ s/\%20/ /g;
		$input{xml} =~ s/\%27/\'/g;
		$input{xml} =~ s/\%22/\"/g;
		$input{xml} =~ s/\%3B/\;/g;
		$input{xml} =~ s/\%3A/\:/g;
		$input{xml} =~ s/\%3C/\</g;
		$input{xml} =~ s/\%3E/\>/g;
		
		$input{xml} =~ s/\&gt\;/\>/g;
		$input{xml} =~ s/\&lt\;/\</g;
		$input{xml} =~ s/\&amp;/\&/g;
		$input{xml} =~ s/\&quot;/\"/g;
		$input{xml} =~ s/\&apos\;/\'/g;
		
		$input{xml} =~ s/\>\s*\</\>\</g;
		
		my $sysdate = sysdate();
		
		my $sth = $dbh->prepare(qq~UPDATE autoBot SET deployedDate=?, idUserDeploy=?, autoBotXML=? WHERE idAutoBot=?~);
		$sth->execute($sysdate, $myIDuser, $input{xml}, $input{autoBotId});
		$sth->finish;
		$dbh->disconnect if $dbh;
	}
	
	print "Location: index.cgi?mod=design&submod=edit_autobot&autoBotId=$input{autoBotId}\n\n";
}



if ( $input{submod} eq 'save_autobot_data' ) {
	connected();
	my $sth = $dbh->prepare("SELECT idUser FROM users WHERE username = '$username'");
	$sth->execute();
	my ($myIDuser) = $sth->fetchrow_array;
	$sth->finish;
	
	my $sth = $dbh->prepare("SELECT * FROM autoBot WHERE idAutoBot = '$input{autoBotId}'");
	$sth->execute();
	my @ABOT = $sth->fetchrow_array;
	$sth->finish;
	
	my $insert_string = "INSERT INTO autoBotHistory (idAutoBot, autoBotName, description, deployedDate, idUserDeploy, active, autoBotXML) 
	VALUES (?, ?, ?, ?, ?, ?, ?)";
	$sth = $dbh->prepare("$insert_string");
	$sth->execute($ABOT[0], $ABOT[1], $ABOT[2], $ABOT[3], $ABOT[4], $ABOT[5], $ABOT[6]);
	$sth->finish;
	
	my $sysdate = sysdate();
	
	connected();
	my $sth = $dbh->prepare("UPDATE autoBot SET 
	deployedDate='$sysdate', 
	idUserDeploy='$myIDuser', 
	autoBotName='$input{autoBotName}', 
	description='$input{description}', 
	active='$input{active}' 
	WHERE idAutoBot='$input{autoBotId}'");
	$sth->execute();
	$sth->finish;
	$dbh->disconnect if $dbh;
	
	print "Location: index.cgi?mod=design&submod=edit_autobot&autoBotId=$input{autoBotId}\n\n";
}








if ( $input{submod} eq 'downloadXML' ) {
	connected();
	my $sth = $dbh->prepare("select autoBotXML from autoBot where idAutoBot = '$input{idAutoBot}'");
	$sth->execute();
	my ($myXML) = $sth->fetchrow_array;
	$sth->finish;
	
	my $q = CGI->new;
	print $q->header(
		-type            => 'application/x-download',
		-attachment      => "$input{idAutoBot}.xml",
		-Content_length  => length $myXML
	);
	
	print $myXML;
	exit;
}








if ( $input{submod} eq 'edit_autobot' ) {
	$html .= qq~<div class="contentTitle">$MSG{Autobots_Design}</div>~ unless $input{'shtl'};
	
	my $QUERY = qq~SELECT * FROM autoBot WHERE idAutoBot = '$input{autoBotId}'~;
	my $ADVRT;
	my $CurrDeploy;
	if ( $input{HistoricView} ) {
		$QUERY = qq~SELECT idAutoBot,autoBotName,description,deployedDate,idUserDeploy,active,autoBotXML FROM autoBotHistory WHERE idAutoBot = '$input{autoBotId}' AND idABhistory = '$input{HistoricView}'~;
		$ADVRT = qq~
		<font color="#DD0000" style="padding-left: 20px; font-size: 130%;">$MSG{You_are_viewing_a_historic_data_Please_be_careful_with_your_actions}.</font>
		<br><br>
		~;
		$CurrDeploy = qq~
		<a href="index.cgi?mod=design&submod=edit_autobot&autoBotId=$input{autoBotId}">$MSG{Back_to_current_deploy}</a><br><br>
		~;
	}
	
	connected();
	my $sth = $dbh->prepare("$QUERY");
	$sth->execute();
	my @ABOT = $sth->fetchrow_array;
	$sth->finish;
	
	my $sth = $dbh->prepare("SELECT username FROM users WHERE idUser = '$ABOT[4]'");
	$sth->execute();
	my ($userDeploy) = $sth->fetchrow_array;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	$ABOT[6] =~ s/\'/\\'/g;
	$ABOT[6] =~ s/\"/\\"/g;
	$ABOT[6] =~ s/\n/\\n/g;
	
	$ABOT[6] =~ s/\&gt\;/\>/g;
	$ABOT[6] =~ s/\&lt\;/\</g;
	$ABOT[6] =~ s/\&amp\;/\&/g;
	$ABOT[6] =~ s/\&quot\;/\"/g;
	$ABOT[6] =~ s/\&apos\;/\'/g;
	
	my $chkActive;
	my $chkUnActive;
	if ( $ABOT[5] eq '1' ) {
		$chkActive = 'checked';
		$chkUnActive = '';
	} else {
		$chkActive = '';
		$chkUnActive = 'checked';
	}
	
	$html .= qq~
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="design">
	<input type="hidden" name="submod" value="save_autobot_data">
	<input type="hidden" name="autoBotId" value="$ABOT[0]">
	$MSG{AutoBot_Name}: &nbsp; <input type="text" name="autoBotName" value="$ABOT[1]" maxlength="100" placeholder="$MSG{Insert_AutoBot_Name}" required> &nbsp; &nbsp; 
	$MSG{Description}: &nbsp; <input type="text" name="description" value="$ABOT[2]" maxlength="255" style="width: 400px;"> <br /><br />
	<font color="#008000">$MSG{Active}</font>&nbsp;<input type="radio" name="active" value="1" $chkActive> &nbsp; 
	 &nbsp; <input type="radio" name="active" value="0" $chkUnActive>&nbsp;<font color="#A52A2A">$MSG{InActive}</font> &nbsp; &nbsp; 
	<input class="blueLightButton" type="submit" value="$MSG{Update_Data}">
	</form>
	<br>
	
	
	
	<form method="post" action="index.cgi" id="loadxml">
	<input type="hidden" name="mod" value="design">
	<input type="hidden" name="submod" value="save_autobot_xml">
	<input type="hidden" name="autoBotId" value="$input{autoBotId}">
	
	<br>
	<hr style="border-bottom: 1px solid #0000FF" noshade>
	<br>
	
	$ADVRT
	<br>
	
	$MSG{Deployed_by} <i>$userDeploy</i> $MSG{on} $ABOT[3]
	
	<font color="#BB0000" style="padding-left: 200px;">$MSG{Load_Restore_XML}</font>: <input type="text" name="xml" placeholder="$MSG{Enter_XML_code}" required>
	<button class="blueLightButton" type="submit" form="loadxml" value="$MSG{Restore_This_XML}">$MSG{Restore_This_XML}</button>
	</form>
	
	
	
	$MSG{XML_Edition}:~;
	# $html .= qq~ &nbsp;  &nbsp;  &nbsp;  &nbsp;  &nbsp;  &nbsp; &nbsp;  &nbsp;  &nbsp;  &nbsp;  &nbsp;  &nbsp; 
	# <font color="#EE0000"><b>**</b></font> &nbsp; $MSG{quotes_greaterthan_lessthan_semicolon} &nbsp; <font color="#EE0000"><b>**</b></font>
	# ~;
	
	unless ( $VAR{DESIGNER_SET_MODE} =~ /^laic|nerd$/ ) {
		$VAR{DESIGNER_SET_MODE} = 'nerd';
	}
	my $setmode = 'Xonomy.setMode("' . $VAR{DESIGNER_SET_MODE} . '");';
	
	my $nerdChecked, $laicChecked;
	if ( $VAR{DESIGNER_SET_MODE} eq 'nerd' ) {
		$nerdChecked = 'checked="checked"';
	} elsif ( $VAR{DESIGNER_SET_MODE} eq 'laic' ) {
		$laicChecked = 'checked="checked"';
	}
	
	$html .= qq~<br><br>
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr><td style="width: calc(100% - 150px);" valign="top">
	~;
	
	$html .= qq~
	<script type="text/javascript">
		function start() {
			
			var docSpec=specifications;
			$setmode
			
			var xml='$ABOT[6]';
			var editor=document.getElementById("editor");
			Xonomy.render(xml, editor, docSpec);
		}
		
		function submit() {
			var xml=Xonomy.harvest(); //XML
			//var url="index.cgi?mod=design&submod=save_autobot_xml&autoBotId=$ABOT[0]&xml=" + Xonomy.harvest();
			var url="index.cgi?mod=design&submod=save_autobot_xml&autoBotId=$ABOT[0]&xml=" + encodeURIComponent(xml);
			//window.location = url
			location.href = url
			//alert(url);
		}
		
		function setMode() {
			var mode=\$("input[name='mode']:checked").val();
			Xonomy.setMode(mode);
		}
	</script>
	</head>
	<body onload="start()">
		<span class="radios">
			<label onclick="setMode()"><input type="radio" name="mode" value="nerd" id="chkModeNerd" $nerdChecked/>nerd mode</label> &nbsp; &nbsp; 
			<label onclick="setMode()"><input type="radio" name="mode" value="laic" id="chkModeLaic" $laicChecked/>laic mode</label>
		</span>
	<br><br>
		<div id="editor" class="editor"></div>
	<br>
	
	<form style="display:inline;"><input class="blueLightButton" type="button" value=" $MSG{Get_XML} " onclick="window.location.href='launcher.cgi?mod=design&submod=downloadXML&idAutoBot=$ABOT[0]'" /></form>
	&nbsp; &nbsp; &nbsp; 
	
	
	
		<script>
			function openModal(modalId) {
				document.getElementById(modalId).style.display = "block";
			}
			function closeModal(modalId) {
				document.getElementById(modalId).style.display = "none";
			}
			function openModalRedirect(modalId, htmlink, targetLink) {
				document.getElementById(modalId).style.display = "block";
				window.open(htmlink, targetLink);
			}
			function openModalCloseAndRedirect(modalIdToOpen, modalIdToClose, htmlink, targetLink) {
				document.getElementById(modalIdToClose).style.display = "none";
				document.getElementById(modalIdToOpen).style.display = "block";
				//window.open(htmlink, targetLink);
				submit();
			}
		</script>
		
		<div id="myModalRedirectStop" class="confirm"><div class="confirm-content">
			$MSG{Alert}<hr class="confirm-header">
			$MSG{Updating_AutoBot}.<br />$MSG{Please_wait_a_while_and_dont_close_this_window}
		</div></div>
		
		<div id="myModalConfirmStop" class="confirm"><div class="confirm-content">
			$MSG{Please_confirm}<hr class="confirm-header">
			$MSG{Are_you_sure_you_want_to_update_this_AutoBot} ?
			<span class="confirm-bottom">
			<button onClick="return openModalCloseAndRedirect('myModalRedirectStop', 'myModalConfirmStop', '', '_top');" class="blueLightButton">$MSG{Yes}</button>
			<button onClick="return closeModal('myModalConfirmStop');" class="greyButton">$MSG{Cancel}</button>
			</span>
		</div></div>
		
		<button class="blueLightButton" onClick="return openModal('myModalConfirmStop');">~;
	
	$html .= $input{HistoricView} ? $MSG{Restore_This_AutoBot} : $MSG{Update_AutoBot} ;
	
	$html .= qq~</button>
	<br /><p style="padding-bottom: 200px;" /><br />
	~;
	
	
	
	
	connected();
	my $sth1 = $dbh->prepare("SELECT idABhistory, deployedDate, idUserDeploy FROM autoBotHistory WHERE idAutoBot = '$input{autoBotId}' ORDER BY deployedDate DESC");
	$sth1->execute();
	my $ABhistory = $sth1->fetchall_arrayref;
	$sth1->finish;
	
	my $sth = $dbh->prepare("SELECT idUser, username FROM users");
	$sth->execute();
	my $users = $sth->fetchall_arrayref;
	$sth->finish;
	$dbh->disconnect if ($dbh);
	
	my %USR;
	for my $i ( 0 .. $#{$users} ) {
		$USR{$users->[$i][0]} = $users->[$i][1];
	}
	
	$html .= qq~
	</td>
	<td style="width: 150px;" valign="top">
	<b>$MSG{Autobot_History}</b><br>
	<div style="width: 150px; height: 600px; background-color: #ECECEC; border: 1px solid #DEDEDE; padding: 4px; overflow-y: scroll;">
	$CurrDeploy
	~;
	
	for my $i ( 0 .. $#{$ABhistory} ) {
		$html .= qq~
		<a href="index.cgi?mod=design&submod=edit_autobot&HistoricView=$ABhistory->[$i][0]&autoBotId=$input{autoBotId}">$ABhistory->[$i][1]</a><br>
		$MSG{Deployed_by}: <i>$USR{ $ABhistory->[$i][2] }</i>
		<br><br>
		~;
	}
	
	$html .= qq~
	</div>
	</td></tr></table>
	~;
}
#<button class="blueLightButton" onclick="alert(Xonomy.harvest())"> $MSG{Get_XML} </button>



if ( $input{submod} eq 'cryptPasswd' ) {
	$html .= qq~<div class="contentTitle">$MSG{Encrypt_Password}</div>~ unless $input{'shtl'};
	
	my $longKey = $input{longKey} || 24;
	my $passwd = $input{passwd};
	my $encKey = generateRandomKey($longKey);
	
	my $encryptedPass;
	if ( $passwd ) {
		use Crypt::Babel;
		my $crypt = new Crypt::Babel;
		$encryptedPass = $crypt->encode($passwd, $encKey);
	}
	
	$html .= qq~<table cellpadding="0" cellspacing="0"><tr><td align="right">
	
	<form method="post" action="index.cgi">
	<input type="hidden" name="mod" value="design">
	<input type="hidden" name="submod" value="cryptPasswd">
	<input type="hidden" name="encKey" value="$encKey">
	
	$MSG{Password}: &nbsp; <input type="password" name="passwd" maxlength="60" placeholder="$MSG{Enter_the_password_to_encrypt}" value="$passwd" required> <br />
	$MSG{Long_of_the_Encryption_Key}: &nbsp; <input type="text" name="longKey" maxlength="128" placeholder="$MSG{Enter_long_of_Encryption_Key}" value="$longKey" required> <br />
	<br />
	<input class="blueLightButton" type="submit" value="$MSG{Generate}">
	<br />
	<br />
	<br />
	$MSG{Encryption_Key}: &nbsp; <input type="text" value="$encKey"> <br />
	$MSG{Encrypted_Password}: &nbsp; <input type="text" value="$encryptedPass">  <br />
	
	</form>
	
	</td></tr></table>~;
	
	
}

return $html;

sub generateRandomKey {
	my @chars = ('a'..'z',0..9,'A'..'Z',0..9);
	my $long = shift;
	my $key;
	for ( 1 .. $long ) {
		$key .= $chars[int(rand(@chars))];
	}
	return $key;
}

sub sysdate {
	my @fecha = localtime(time); # sec,min,hour,mday,mon,year,wday,yday ,isdst
	$fecha[5] += 1900;
	$fecha[4] ++;
	@fecha = map { if ($_ < 10) { $_ = "0$_"; }else{ $_ } } @fecha;
	return my $sysdate = "$fecha[5]-$fecha[4]-$fecha[3] $fecha[2]:$fecha[1]:$fecha[0]";
}

1;

