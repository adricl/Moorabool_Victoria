 use WWW::Mechanize::PhantomJS;
 use HTML::TreeBuilder;
 use Database::DumpTruck;
 use Data::Dumper;
 use HTML::TreeBuilder::XPath;
 use HTTP::Request;
 use LWP::UserAgent;
 use HTTP::Request::Common;
 use HTTP::Cookies;

  my $base_url = 'https://greenlight.e-vis.com.au/moorabool/public/';
  my $search_url = 'main.aspx?frm=uc_search_AdvertisingApplications.ascx&appTypeId=1&mId=232';
  #Db Handle
  my $dt = Database::DumpTruck->new({dbname => 'data.sqlite', table => 'data'});

  my $mech = WWW::Mechanize::PhantomJS->new();

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


  $mech->get($base_url . $search_url);
  $mech->click_button( id => '_ctl0_btnSearch'); #Search Button

  my $html_raw = $mech->content( raw => 1 );
  my $tree = HTML::TreeBuilder->new_from_content($html_raw);
  my @table = $tree->findnodes('//table[@id="_ctl0_tblSearchResults"]/tbody');
  my @table_data = $table[0]->content_list();

  for(my $i = 0; $i < scalar @table_data; $i++)
  {
	  $curr_row = $table_data[$i];
	  my $tableId = $curr_row->look_down( _tag  => 'tr', class => 'tableHead' );
	  if(!($tableId ne undef))
	  {
		my @arr = $curr_row->look_down( _tag => 'a');
		my $addr = $base_url .  $arr[0]->attr('href');
		my $id = ${$arr[0]->content_refs_list};
		
		if(!id_found($id, $dt))
		{
			
		}
	  }
  }

  sub get_data_page 
  {
	my ($mech, $address, $dt) = @_;
  }
  
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
  
  #print Dumper @table_data;
  #close FH;
  #print Dumper $table;

  #next page
  #$mech->click_button( id => '_ctl0_ucPageControl_imgPageForward');
  #print $mech->content( raw => 1 );
  #print $mech->text();
  #my $png= $mech->content_as_png();
  # print $_->{message}
  #    for $mech->js_errors();
  #print $mech->base;

