
BEGIN {
	# $ENV{HTTPS_VERSION} = 3;
	 $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}


 use POSIX;
 use HTML::TreeBuilder;
 use Database::DumpTruck;
 use Data::Dumper;
# use HTML::TreeBuilder::XPath; #Removed Xpath as it does not work with Morph.io
 use HTTP::Request;
 use LWP::Protocol::https;
 use LWP::UserAgent;
 use HTTP::Request::Common;
 use HTTP::Cookies;
 use WWW::Mechanize;
 use WWW::Mechanize::PhantomJS;
 use IO::Socket::SSL;
 use Mozilla::CA;
 #use Crypt::SSLeay;


  my $base_url = 'https://greenlight.e-vis.com.au/moorabool/public/';
  my $search_url = 'main.aspx?frm=uc_search_AdvertisingApplications.ascx&appTypeId=1&mId=232';
  #Db Handle
  my $dt = Database::DumpTruck->new({dbname => 'data.sqlite', table => 'data'});

  my $mech = WWW::Mechanize::PhantomJS->new(ssl_opts => {
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
    verify_hostname => 0, });
  #$mech->ssl_opts( SSL_version => 'SSLv3');
#$dt->insert([{
#     council_reference => '',
#     address => '',
#	 description => '',
#	 info_url => '',
#	 comment_url => '',
#	 date_scraped => '',
#	 date_received => '',
#	 on_notice_from => '',
#	 on_notice_to => ''
# }]);



#
#
#

  my $ua = LWP::UserAgent->new;
  $ua->cookie_jar(HTTP::Cookies->new(file => "cookie_jar", autosave => 1));
  my $request = $ua->request(GET $base_url . $search_url);
  #print $request->content( raw => 1 ); 

  $mech->get($base_url . $search_url);
  #print $mech->content( raw => 1 );
  $mech->click_button( id => '_ctl0_btnSearch'); #Search Button click to load new session

  my $html_raw = $mech->content( raw => 1 );
  my $tree = HTML::TreeBuilder->new_from_content($html_raw);
  my $table = $tree->find_by_attribute('id', '_ctl0_tblSearchResults'); #find the table to read
  my $table_body = $table->look_down(_tag => 'tbody');

  my @table_data = $table_body->content_list();

  for(my $i = 0; $i < scalar @table_data; $i++)
  {
	  print "Processing: " . ($i + 1) . " out of " . scalar @table_data . "\n";
	  $curr_row = $table_data[$i];
	  my $tableId = $curr_row->look_down( _tag  => 'tr', class => 'tableHead' );
	  if(!($tableId ne undef))
	  {
		my @arr = $curr_row->look_down( _tag => 'a'); #parse the id to work out if we need to process it
		my $addr = $base_url .  $arr[0]->attr('href');
		my $id = ${$arr[0]->content_refs_list};
		
		if(!id_found($id, $dt))
		{
			get_data_page($mech, $addr, $dt);
		}
	  }
  }

  #Load page into database 
  sub get_data_page 
  {
	my ($mech, $web_address, $dt) = @_;
	$mech->get($web_address);
	my $html_raw = $mech->content( raw => 1 );
	my $tree = HTML::TreeBuilder->new_from_content($html_raw);
	#print $tree->find_by_attribute('id', '_ctl0_lblApplicationNo')->as_text . "\n"
	my $now = time();
	my $iso_date = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($now)), "\n";
	$dt->insert({
    	council_reference => $tree->find_by_attribute('id', '_ctl0_lblApplicationNo')->as_text,
     	address => $tree->find_by_attribute('id', '_ctl0_lblAddress')->as_text,
		description => $tree->find_by_attribute('id', '_ctl0_lblApplicationDescription')->as_text,
		info_url => $web_address,
		comment_url => $web_address,
		date_scraped => $iso_date,
		date_received => '',
		on_notice_from => '',
		on_notice_to => ''
	});
  }
 
  #check the database for id 
  sub id_found
  {
	  my ($id, $dt) = @_;

	  my $ret_ar = eval {$dt->execute('select count(*) from data where council_reference = ?', $id ); };
	  if ($EVAL_ERROR || ! @{$ret_ar} || ! exists $ret_ar->[0]->{'count(*)'}
		|| ! defined $ret_ar->[0]->{'count(*)'}
		|| $ret_ar->[0]->{'count(*)'} == 0) 
	   {
			return 0;
	   }
	   return 1;
  }
  

