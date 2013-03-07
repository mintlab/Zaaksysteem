package Zaaksysteem::Controller::Search;

use strict;
use warnings;
use Data::Dumper;

use parent 'Catalyst::Controller';
use Zaaksysteem::Constants;

use Moose;

has 'page' => (
	is => 'rw',
);


#
# June 2011 - new search functionality, TRAC #168. 
#


############################ begin URL dispatching #####################################

#/search
#/search/345
#/search/results
#/search/433/results
#/search/presentation
#/search/456/presentation



# match /search
sub base :Chained("/") :PathPart("search") :CaptureArgs(0) {
	my ($self, $c) = @_;

	$c->stash->{'user_uidnumber'} = $c->user->uidnumber;
}


# match /search$
sub filters :Chained("base") :PathPart("") :Args(0) {
	my ($self, $c) = @_;
	
	$self->show_filters($c);
}

# match /account (end of chain)
sub presentation :Chained("base") :PathPart("presentation") :Args(0) {
	my ($self, $c) = @_;
	
#	$c->log->debug('presentation from session');
	$self->show_presentation($c);
}


# match /account (end of chain)
#sub grouping :Chained("base") :PathPart("grouping") :Args(0) {
#	my ($self, $c) = @_;
	
#	$c->log->debug('presentation from session');
#	$self->show_grouping($c);
#}



# match /account (end of chain)
sub results :Chained("base") :PathPart("results") :Args(0) {
	my ($self, $c) = @_;
	
#	$c->log->debug('results from session');
	$self->show_results($c);
}



#
# read the search_query_id from the url
#
sub id :Chained("base") :PathPart("") :CaptureArgs(1) {
	my ($self, $c, $search_query_id) = @_;
	
    $c->stash->{query_record} = $c->model('DB::SearchQuery')->find($search_query_id);
	$c->stash->{SEARCH_QUERY_SESSION_VAR()} = $search_query_id;
}


#
# match /search/* (end of chain)
#
sub filters_by_id :Chained("id") :PathPart("") :Args(0) {
	my ($self, $c) = @_;
	
	$self->show_filters($c);
}

#
# match /search/*/edit (end of chain)
#
sub presentation_by_id :Chained("id") :PathPart("presentation") :Args(0) {
	my ($self, $c) = @_;
	
#	$c->log->debug('presentation_by_id: '.$c->stash->{SEARCH_QUERY_SESSION_VAR()}.'/edit');
	$self->show_presentation($c);
}

#
# match /search/*/edit (end of chain)
#
sub results_by_id :Chained("id") :PathPart("results") :Args(0) {
	my ($self, $c) = @_;
	
#	$c->log->debug('results_by_id/'.$c->stash->{SEARCH_QUERY_SESSION_VAR()}.'/edit');
    $self->show_results($c);
}


#
# match /search/*/edit (end of chain)
#
#sub grouping_by_id :Chained("id") :PathPart("grouping") :Args(0) {
#	my ($self, $c) = @_;
#	
#    $self->show_grouping($c);
#}





sub chart :Chained("base") :PathPart("results/chart") :Args(0) {
	my ($self, $c) = @_;

	my $params = $c->req->params;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);

	my $chart_profile = $params->{'chart_profile'};
	if($chart_profile) {
		$c->stash->{json} = $self->_chart_profile($c, $chart_profile);
		$c->forward('Zaaksysteem::View::JSON');
		$c->detach;
	}

    $c->stash->{total_results} = $search_query->results($c, 1, 'GET_TOTAL')->pager->total_entries;
    $c->stash->{grouping_field_options} = $search_query->grouping_field_options;

	$c->stash->{'template'} = 'search/chart.tt';
}


sub chart_by_id :Chained("id") :PathPart("results/chart") :Args(0) {
	my ($self, $c) = @_;
	
    $self->chart($c);
}



#
# supply the popup with the settings for a filter - works purely on cgi params, no id handling necessary
#
sub search_edit_filter : Chained('base'): PathPart('filter/edit'): Args() {
    my ($self, $c) = @_;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);

	my $params = $c->req->params();
	
	$c->stash->{filter_data} = $self->_search_query($c)->edit_filter(
		$params->{filter_type}, 
		$params->{filter_value},
	);

	$c->stash->{SEARCH_QUERY_SESSION_VAR()} = $params->{SEARCH_QUERY_SESSION_VAR()};
    $c->stash->{nowrapper} = 1;

    $c->stash->{org_eenheden} = $c->model('Betrokkene')->search(
        {
            type    => 'org_eenheid',
            intern  => 0,
        },
        {}
    );

    $c->stash->{template} = 'search/edit_filter.tt';
}


sub save_settings : Chained('base'): PathPart('save'): Args() {
    my ($self, $c) = @_;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);
	$c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'search/save.tt';
    #TODO
}

sub save_settings_id : Chained('id'): PathPart('save'): Args() {
    my ($self, $c) = @_;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);
	$c->stash->{nowrapper} = 1;
    $c->stash->{template} = 'search/save.tt';
    #TODO
}


sub reset : Chained('base'): PathPart('reset'): Args() {
    my ($self, $c) = @_;

	delete $c->session->{SEARCH_QUERY_SESSION_VAR()};
#	$c->log->debug("session" . $c->session->{SEARCH_QUERY_SESSION_VAR()});
	$c->response->redirect($c->uri_for('/search'));
	$c->detach();
}


sub dashboard: Chained('base'): PathPart('dashboard'): Args() {
    my ($self, $c) = @_;
	
	$self->_handle_dashboard_updates($c);

    if($c->req->param('action') eq 'update_sort_order') {
   		$c->stash->{json} = {'result' => 1 };
		$c->forward('Zaaksysteem::View::JSON');
		$c->detach;
    }

    my $options = {
        'order_by'  => {'-asc' => 'sort_index'},
        page        => 1,
        rows        => 10000,
        join        => [ 'search_query_delens' ],
        distinct    => 1,
        #'select'    => { 'distinct'    => [ $c->model('DB::SearchQuery')->result_source->columns ] },
        #'as'        => [ $c->model('DB::SearchQuery')->result_source->columns ],
    };
    
    if($c->stash->{'show_more_search_queries'}) {
        $options->{'page'} = 1;
        $options->{'rows'} = 10;
    }

	$c->stash->{'search_queries'} = $c->model('DB::SearchQuery')->search(
	    {
            '-or'   => {
                ldap_id => $c->user->uidnumber,
                '-and'  => {
                    'search_query_delens.ou_id'     => $c->user_ou_id,
                    'search_query_delens.role_id'   => {
                        '-in'   => [ $c->user_roles_ids ]
                    },
                }
            }
        },
	    $options,
	);
		
    $c->stash->{template} = 'search/dashboard.tt';	
}

sub opties : Chained('id'): PathPart('opties'): Args() {
    my ($self, $c) = @_;

    my $search_query = $self->_search_query($c);

    ### Tempalte
    $c->stash->{template} = 'search/widgets/opties.tt';

    $c->stash->{zoekopdracht_beveiligen} = 1 if
        ($search_query->access eq 'private');


    ### DB settings
    my $delen   = $c->stash->{query_record}
        ->search_query_delens
        ->search({}, { order_by => 'id' });

    my $counter = 0;
    while (my $deel = $delen->next) {
        $c->stash->{delen}->{++$counter} = $deel;
    }

    if (uc($c->req->method) eq 'POST' && $c->req->params->{update}) {
        $c->res->redirect($c->uri_for(
            '/search/' .
            $c->stash->{query_record}->id
        ));

        my @rollen  = grep { /^delen/ } keys %{ $c->req->params };

        my $rv      = {};
        for my $rol (@rollen) {
            my ($id)    = $rol =~ /(\d+)$/;
            next unless $id;

            $rv->{$id}  = {
                role_id     => $c->req->params->{'delen.role_id.' . $id},
                ou_id       => $c->req->params->{'delen.ou_id.' . $id},
            }
        }

        ### update
        my @ids     = sort(keys %{ $rv });

        $c->stash->{query_record}->search_query_delens->delete;
        for my $id (@ids) {
            $c->stash->{query_record}->search_query_delens->create(
                $rv->{$id}
            )
        }

        ### Zoekopdracht beveiligen
        if ($c->req->params->{zoekopdracht_beveiligen}) {
            $search_query->access('private');
        } else {
            $search_query->access('public');
        }

        $self->_save($c, $search_query);
    }
}



sub get : Chained('/'): PathPart('search/get'): Args(0) {
    my ($self, $c) = @_;

    (
        $c->res->redirect('/'),
        return
    ) unless (
        exists($c->req->params->{searchstring}) &&
        $c->req->params->{searchstring}
    );

    my $sstring = $c->req->params->{searchstring};

    if ($c->req->params->{component} eq 'zaak') {
        if (
            $sstring =~ /^\d+$/
        ) {
            $c->res->redirect('/zaak/' . $sstring);
            $c->detach;
        }
    } elsif ($c->req->params->{component} eq 'natuurlijk_persoon') {
        $c->res->redirect(
            $c->uri_for(
                '/betrokkene/search',
                {
                    'np-geslachtsnaam'  => $sstring,
                    'betrokkene_type'   => 'natuurlijk_persoon',
                    'search'            => 1,
                }
            )
        );
        $c->detach;
    } elsif ($c->req->params->{component} eq 'bedrijf') {
        $c->res->redirect(
            $c->uri_for(
                '/betrokkene/search',
                {
                    'handelsnaam'       => $sstring,
                    'betrokkene_type'   => 'bedrijf',
                    'search'            => 1,
                }
            )
        );
        $c->detach;
    }

    $c->res->redirect('/');
}


############################ end of URL dispatching #####################################


sub _handle_dashboard_updates {
	my ($self, $c) = @_;

	my $params = $c->req->params();
	my $action = $params->{'action'} || '';

	if($action eq 'delete_search_query') {
		my $search_query_id = $params->{'search_query_id'};
		die "need search query id" unless($search_query_id);
		
		my $model = $c->model(SEARCH_QUERY_TABLE_NAME);
		my $record = $model->find($search_query_id);
		
		return unless($record);

		if($record->ldap_id eq $c->user->uidnumber) {
			$record->delete;
		}
	} elsif($action eq 'update_sort_order') {
	    my @id_strings = grep /^search_query_id_/, keys %$params;
	    my $sort_index = 0;
        my $model = $c->model(SEARCH_QUERY_TABLE_NAME);

        @id_strings = sort { $params->{$a} <=> $params->{$b} } @id_strings; 
	    foreach my $id_string (@id_strings) {
	        my ($search_query_id) = $id_string =~ m|(\d+)|;
	        $c->log->debug('search_query_id: ' . $search_query_id);

            my $record = $model->find($search_query_id);
	        if($record) {
	            $c->log->debug('record found');
	            $record->sort_index($sort_index);
	            $record->update();
	        }
	        $sort_index++;
	    }
	}
}



sub show_filters {
    my ($self, $c) = @_;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);
	
	my $params = $c->req->params();

	if($params->{nowrapper} && $params->{nowrapper} == 1) {
		$c->stash->{nowrapper} = 1;
	}
	
	$c->stash->{filter_type} = $params->{'filter_type'};
	$c->stash->{active_filtertype} = $params->{'filter_type'};
	$c->stash->{filters} = $search_query->get_filters($c);
	$c->stash->{kenmerken} = $search_query->get_kenmerken($c);

    $c->stash->{grouping_field_options} = $search_query->grouping_field_options;

    $c->stash->{total_results} = $search_query->results($c, 1, 'GET_TOTAL')->pager->total_entries;
    
	$c->stash->{filtertypes} = $search_query->filter_options;
    $c->stash->{template} = 'search/filters.tt';
}




sub show_presentation {
    my ($self, $c) = @_;

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);

	my $display_fields = $search_query->edit_display_fields();
#	$c->log->debug("display fields: " . scalar(@$display_fields));	
	$c->stash->{display_fields} = $display_fields;

	$c->stash->{grouping_field} = $search_query->grouping_field;
	$c->stash->{grouping_field_options} = $search_query->grouping_field_options;

    $c->stash->{total_results} = $search_query->results($c, 1, 'GET_TOTAL')->pager->total_entries;
	
    $c->stash->{template} = 'search/presentation.tt';
}



#
# display the results
#
sub show_results {
    my ($self, $c) = @_;

	my $params = $c->req->params();
	if($params->{'filetype'}) {
		return $self->document($c, $params->{'filetype'});
	}

    if($c->req->params->{statusfilter}) {
        $params->{filter} = $c->req->params->{statusfilter};
    }

	# default page, to be overridden somewhere down the line
	$self->page(1);

	my $search_query = $self->_search_query($c);
	$self->_process_input($c, $search_query);

	my $resultset;

    if (!$search_query->sort_field) {
        $search_query->sort_field('me.id');
    }

    my $grouping_field = $c->stash->{'grouping_field'} = $params->{'grouping_field'};
    $search_query->grouping_field($grouping_field);
    if($grouping_field && !$params->{grouping_choice}) {
        $search_query->sort_field(undef);
    }

    my $grouping_choice = $c->stash->{'grouping_choice'} = $params->{'grouping_choice'};
    if($grouping_choice) {
   		$search_query->grouping_choice($grouping_choice);
    } else {
   		$search_query->grouping_choice(undef);
    }

    $resultset = $search_query->results($c, $self->page)->with_progress();

	# use the central filter code to handle the dropdown and textfilter limiting filter options    
	$resultset = $c->model('Zaken')->filter({
		resultset 	   => $resultset,
		textfilter     => $params->{'textfilter'},
		dropdown	   => $params->{'filter'},
	});

    $c->stash->{total_results} = $search_query->results($c, 1, 'GET_TOTAL')->pager->total_entries;

    $c->stash->{'results'} = $resultset;
    $c->stash->{grouping_field_options} = $search_query->grouping_field_options;
    
    if($grouping_field) {
        $c->stash->{total_results} = $search_query->results($c, 1, 'GET_TOTAL')->pager->total_entries;
    }

    if($grouping_field && !$grouping_choice) {
        $c->stash->{status_labels} = $search_query->status_labels;
        $c->stash->{template} = 'search/grouping.tt';
    } else {
        $c->stash->{sort_field} = $search_query->sort_field;
        $c->stash->{sort_direction} = $search_query->sort_direction;	
        $c->stash->{'page'} = $self->page();
        $c->stash->{display_fields} = $search_query->get_display_fields;
        $c->stash->{template} = 'search/results.tt';
    }
}


sub document {
    my ($self, $c, $filetype) = @_;

	my $search_query = $self->_search_query($c);


#application/vnd.oasis.opendocument.spreadsheet, application/x-vnd.oasis.opendocument.spreadsheet
	my $CONFIG = {
		excel  => { mimetype => 'application/vnd.ms-excel', extension => 'xls' },
		oocalc => { mimetype => 'application/vnd.oasis.opendocument.spreadsheet', extension => 'ods' },
		csv    => { mimetype => 'text/csv', extension => 'csv' },
	};

	die "incorrect filetype" unless(exists $CONFIG->{$filetype});

	my $resultset = $search_query->results($c)->with_progress();

    my $display_fields = $search_query->get_display_fields({ plain_text => 1 });;

    my @results = ();
    my @header_row = map {$_->{'label'}} @$display_fields;
    push @results, \@header_row;
    
	while (my $zaak = $resultset->next) {
	    my @row = ();
	    foreach my $display_field (@$display_fields) {
	        my $datafieldname = $display_field->{'systeemkenmerk'};
#	        $c->log->debug('fieldname: ' . $datafieldname);
            ### TRANSLATION
            my $value   = $zaak->systeemkenmerk($datafieldname);

            if (
                $value =~ /^[\w\d_-]+$/ &&
                (my $translation = $c->loc($datafieldname . '_' . $value)) ne
                    $datafieldname . '_' . $value
            ) {
                $value = $translation;
            }

	        push @row, $value;
            #$c->log->debug('value: ' . $zaak->systeemkenmerk($datafieldname));
	        #$zaak->zaaktype_node_id->titel;
	    }
		push @results, \@row;
	}

    $c->log->debug('Render CSV');

	
	# generate a csv string
    $c->stash->{'csv'} = { 'data' => \@results };
    my $csv = $c->view('CSV')->render($c, $c->stash);


# cough up a file
    $c->log->debug('Part of CSV: ' . substr($csv,0,1024));
	use HTTP::Request::Common;
    use Encode qw(encode);

    if (
        !$c->config->{libreoffice_version} ||
        $c->config->{libreoffice_version} < 3
    ) {
        $csv = encode('UTF-8', $csv);
    } else {
        $csv = encode('iso-8859-1', $csv);
    }
	my $ua = LWP::UserAgent->new;
	my $result = $ua->request(POST 'http://localhost:8080/converter/service', 
		Content => $csv,
		Content_Type => 'text/csv',
		Accept => $CONFIG->{$filetype}->{'mimetype'},
	);
	

    $c->res->headers->header( 'Content-Type'  => 'application/x-download' );
    $c->res->headers->header(
        'Content-Disposition'  =>
            "attachment;filename=zaaksysteem-" . time()
            . "." . $CONFIG->{ $filetype }->{extension} . "\n\n"
    );

#    print "Content-Type:application/x-download\n";   <br>  
#    $c->res->header("Content-Disposition:attachment;filename=zaaksysteem-" .time() .".$filetype\n\n";  <br>  

#	$c->res->content_type($CONFIG->{$filetype}->{'mimetype'});
	$c->res->body($result->content);
}

sub update_sort_field {
	my ($self, $sort_field) = @_;
	
	my $current_sort_field = $self->sort_field || '';
	
	if($current_sort_field eq $sort_field) {
		if($self->sort_direction eq 'ASC') {
			$self->sort_direction('DESC');
		} else {
			$self->sort_direction('ASC');
		}
	} else {
		$self->sort_direction('ASC');
	}
	$self->sort_field($sort_field);
}


# ------------------------------- only friends can see private parts ---------------------------#

#
# process changes to the state of the application
#
sub _process_input {
	my ($self, $c, $search_query) = @_;

	my $params = $c->req->params();
	
	$self->_handle_updates($c, $params, $search_query);
	
	my $search_query_id = $c->stash->{SEARCH_QUERY_SESSION_VAR()} || '';
	my $search_query_id_path = $search_query_id ? '/'. $search_query_id : '';

#	$c->log->debug("action: $action, sqidp: $search_query_id_path");

    my $destination = $params->{'destination'} || '';
	if($destination eq 'filters' && $params->{'current_search_page'} ne 'filters') {
		$c->response->redirect($c->uri_for('/search'. $search_query_id_path));
		$c->detach();
	} elsif($destination eq 'presentation' && $params->{'current_search_page'} ne 'presentation') {
		$c->response->redirect($c->uri_for('/search'. $search_query_id_path ."/presentation"));
		$c->detach();
	} elsif($destination eq 'results' && $params->{'current_search_page'} ne 'results') {
		$c->response->redirect($c->uri_for('/search'. $search_query_id_path ."/results"));
		$c->detach();			
	} elsif($destination eq 'chart' && $params->{'current_search_page'} ne 'chart') {
		$c->response->redirect($c->uri_for('/search'. $search_query_id_path ."/results/chart"));
		$c->detach();			
	}
	
	$c->stash->{'current_filter_type'} = $c->session->{'current_filter_type'};
}


sub _handle_updates {
	my ($self, $c, $params, $search_query) = @_;
	
	my $action = $params->{'action'} || '';

	if($action eq 'show_kenmerken_filters') {
		$c->stash->{'show_kenmerken_filters'} = 1;
	}

	if($action eq 'reset') {
		delete $c->session->{SEARCH_QUERY_SESSION_VAR()};
		$c->response->redirect($c->uri_for('/search'));
		$c->detach();
	}

   # update access settings if supplied
   #if($params->{'search_query_access_hidden'}) {
   #     $search_query->access($params->{'search_query_access_hidden'});
   #     $c->stash->{'search_query_access'} = $params->{'search_query_access_hidden'};
   # }

	# avoid saving unless something has changed
#	return unless($action =~ m|^update_|);

#    if($params->{'grouping_field'}) {
#		$search_query->grouping_field($params->{grouping_field});
#    } else {
#		$search_query->grouping_field(undef);    
#    }
	# if search_fields where sent, update them

	if($action eq 'update_presentation') {
        my $search_fields = $self->_make_list($c, $params->{search_fields});
        if($params->{'additional_kenmerk'}) {
	        push @$search_fields, $params->{'additional_kenmerk'};    
	    }
		$search_query->set_display_fields($search_fields);
	} 
	elsif($action eq 'update_filter') {
		# make sure all kenmerk updates and deletions are taken care of
#		$self->_update_filters($c, $search_query, $params);
		$search_query->update_filter($params);
		$c->session->{'current_filter_type'} = $params->{'filter_type'};
	}
	elsif($action eq 'update_filters') {
		$self->_update_filters($c, $search_query, $params);
	}
	elsif($action eq 'update_results') {
        $self->page($params->{'page'} || 1);
        ### Do not change sort direction on page change
        unless ($params->{pager_request}) {
            $search_query->update_sort_field($params->{'sort_field'} || '');
        }
	}

	$self->_save($c, $search_query);
}


sub _update_filters {
	my ($self, $c, $search_query, $params) = @_;

	my $filter_type = $self->_make_list($c, $params->{filter_type});
	my $filter_value = $self->_make_list($c, $params->{filter_value});

	$c->session->{'current_filter_type'} = $params->{'current_filter_type'};
	
	my $kenmerken = [];
	my @kenmerk_indexes = map { $_ =~ m|(\d+)| } grep /^k-kenmerk_id_\d+/, keys %$params;

	foreach my $index_key (sort {$a <=> $b } @kenmerk_indexes) {
		my $index_value    = $params->{'k-kenmerk_id_'.$index_key};
		my $search_value   = $params->{'k-kenmerk_search_'.$index_key} || '';
		my $operator_value = $params->{'k-kenmerk_operator_'.$index_key} || '';

		if($index_value) {
			push @$kenmerken, {
				'id'       => $index_value, 
				'data'     => $search_value, 
				'operator' => $operator_value,
			};
			$c->session->{'current_filter_type'} = 'kenmerk';
		}
	}

	$search_query->update_filters($filter_type, $filter_value, $kenmerken);
}


#
# save the new search settings
#
sub _save {
	my ($self, $c, $search_query) = @_;


#	$c->log->debug('saving: ' . $search_query_id);
	my $params = $c->req->params();
    
	my $serialized = $search_query->serialize();
	my $search_query_id = $c->stash->{SEARCH_QUERY_SESSION_VAR()} || '';


	unless($params->{'search_query_name_hidden'} || $search_query_id) {	
		$c->session->{SEARCH_QUERY_SESSION_VAR()} = $serialized;
		return;
	}

#	$c->log->debug('settings name: ' . 	$c->req->params->{'search_query_name'});

	my $model = $c->model(SEARCH_QUERY_TABLE_NAME);
	my $record;
	
	if($search_query_id) {
		$record = $model->find($search_query_id);
	}
	
	my $search_query_name = $params->{'search_query_name_hidden'};


# if there's no existing record, create one. easy.
    if(!$record) {
    	$record = $model->create({
    		name     => $search_query_name || $record->name,
			ldap_id  => $c->user->uidnumber,
			settings => $serialized,
		});
		my $path = $c->req->path();
		$c->log->debug('path: ' . $path);
		$path =~ s|search|'/search/'.$record->id|eis;
		$c->log->debug('path: ' . $path);
		$c->response->redirect($path);
		$c->detach();
    } else {
        # so there was an existing record.
        # if it's the users own, or it's a public record, update it.
    	if($record->ldap_id eq $c->user->uidnumber || $search_query->access() eq 'public') {
            if($search_query_name) {
                $record->name($search_query_name);
                $c->stash->{'search_query_name'} = $record->name;
            }
            $record->settings($serialized);
            $record->update;
        } else { 
            # so it's a private record of somebody else. don't update, just show results.
            $c->stash->{'search_query_read_only'} = 1;
        }
    }

}


sub _search_query {
	my ($self, $c) = @_;
	die "need c" unless($c);

	my $search_query = $c->model('SearchQuery');
	my $search_query_id = $c->stash->{SEARCH_QUERY_SESSION_VAR()};
	my $model = $c->model(SEARCH_QUERY_TABLE_NAME);
	my $record;
	
	if($search_query_id) {
		my $record = $model->find($search_query_id);
		if($record) {
			$search_query->unserialize($record->settings);
			$c->stash->{'search_query_name'} = $record->name;
			$c->stash->{'record_ldap_id'} = $record->ldap_id;
			$c->stash->{'search_query_access'} = $search_query->access();
			return $search_query;
		} else {
			$c->response->redirect($c->uri_for('/search'));
			$c->detach();
		}
	} else {
		$c->stash->{'search_query_name'} = 'Naamloze zoekopdracht';
		$c->stash->{'search_query_access'} = 'private';
	}

	if($c->session->{SEARCH_QUERY_SESSION_VAR()}) {
		$search_query->unserialize($c->session->{SEARCH_QUERY_SESSION_VAR()});
	}
	
	return $search_query;
}




sub _chart_profile {
	my ($self, $c, $chart_profile) = @_;
	
	die "need chart_profile" unless($chart_profile);

	my $profile;
	
	if($chart_profile eq 'status') {
	
		$profile = {
			chart => {
				renderTo => 'search_query_chart_container',
				defaultSeriesType => 'line',
			},
			title => { text => 'Geregistreerd/afgehandeld' },
			yAxis => { title => { text => 'Zaken' }	},
		};
		my $search_query = $self->_search_query($c);
		my ($rsr,$rsa,$axis)   = $search_query->results($c)->group_geregistreerd();

        unless ($rsa) {
            die('Could not find resultset for chart');
        }

        my $data = [];
        while (my $rsrrow = $rsr->next) {
            my $rsarow      = $rsa->next;
            my $axis_label  = shift(@{ $axis->{x} });

            push(@{ $data },
                {
                    day => $axis_label,
                    geregistreerd => int($rsrrow->zaken),
                    afgehandeld   => int($rsarow->zaken)
                }
            );
        }
        if(@$data) {
            $profile->{xAxis} = {'categories' => [ map {$_->{day}} @$data ]	}; 
    
            my $afgehandeld    = { name => 'Afgehandeld', data => [ map {$_->{afgehandeld}} @$data ]};
            my $geregistreerd  = { name => 'Geregistreerd', data => [ map {$_->{geregistreerd}} @$data ]};
            $profile->{series} = [$afgehandeld, $geregistreerd];
        }
	}
	elsif($chart_profile eq 'afhandeltermijn') {
		$profile = {
			chart => {
				renderTo => 'search_query_chart_container',
			},
		};
		my $search_query = $self->_search_query($c);
		my $resultset = $search_query->results($c)->group_binnen_buiten_termijn();
		my $row = $resultset->first();
		if($row) {
            my $binnen = $row->get_column('binnen');
            my $buiten = $row->get_column('buiten');
            my $total = $binnen + $buiten;

            ### Prevent division by zero
            if ($total) {
                $binnen = int(0.5 + (100* $binnen / $total));
                $buiten = int(0.5 + (100* $buiten / $total));
            } else {
                $binnen = 0;
                $buiten = 0;
            }
    
            $profile->{'title'} = { text => 'Binnen afhandeltermijn/Buiten afhandeltermijn'};
    
            my $series = {
                type => 'pie',
                name => 'Afhandeling',
                data => [
                    {name => 'Binnen', color => 'green', 'y' => $binnen},
                    {name=> 'Buiten', color => 'red', 'y' => $buiten},
                ]
            };
    
            $profile->{series} = [$series];
        }
	}

	return $profile;
}



sub _make_list {
	my ($self, $c, $input) = @_;
	
	return [] unless($input);

	return [$input] unless(ref $input);
	
	return $input if(ref $input eq 'ARRAY');
	
	die "incorrect input: " . Dumper $input;
}

1;

=head1 PROJECT FOUNDER

Mintlab B.V. <info@mintlab.nl>

=head1 CONTRIBUTORS

Arne de Boer

Nicolette Koedam

Marjolein Bryant

Peter Moen

Michiel Ootjers

Jonas Paarlberg

Jan-Willem Buitenhuis

Martin Kip

Gemeente Bussum

=head1 COPYRIGHT

Copyright (c) 2009, the above named PROJECT FOUNDER and CONTRIBUTORS.

=head1 LICENSE

The contents of this file and the complete zaaksysteem.nl distribution
are subject to the EUPL, Version 1.1 or - as soon they will be approved by the
European Commission - subsequent versions of the EUPL (the "Licence"); you may
not use this file except in compliance with the License. You may obtain a copy
of the License at
L<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

=cut

