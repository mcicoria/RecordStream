package App::RecordStream::Operation::xform;

use strict;

use base qw(App::RecordStream::Operation);

use App::RecordStream::Executor;

sub init {
   my $this = shift;
   my $args = shift;

   $this->parse_options($args);
   if(!@{$this->_get_extra_args()}) {
      die "Missing expression\n";
   }

   my $expression = shift @{$this->_get_extra_args()};
   my $executor = App::RecordStream::Executor->new($expression, 1);
   $this->{'EXECUTOR'} = $executor;
}

sub accept_record {
   my $this   = shift;
   my $record = shift;

   my $executor = $this->{'EXECUTOR'};
   $executor->execute_code($record);

   my $value = $executor->get_last_record();

   if ( ref($value) eq 'ARRAY' ) {
     foreach my $new_record (@$value) {
       if ( ref($new_record) eq 'HASH' ) {
         $this->push_record(App::RecordStream::Record->new($new_record));
       }
       else {
         $this->push_record($new_record);
       }
     }
   }
   else {
     $this->push_record($value);
   }
}

sub add_help_types {
   my $this = shift;
   $this->use_help_type('snippet');
}

sub usage {
   return <<USAGE;
Usage: recs-xform <args> <expr> [<files>]
   <expr> is evaluated as perl on each record of input (or records from
   <files>) with \$r set to a App::RecordStream::Record object and \$line set to the current
   line number (starting at 1).  All records are printed back out (changed as
   they may be).

   If \$r is set to an ARRAY ref in the expr, then the values of the array will
   be treated as records and outputed one to a line.  The values of the array
   may either be a hash ref or a App::RecordStream::Record object.  The original record will
   not be outputted in this case.

Examples:
   Add line number to records
      recs-xform '\$r->{line} = \$line'
   Rename field a to b
      recs-xform '\$r->rename("a", "n")'
   Delete field a
      recs-xform '\$r->remove("a")'
   Remove fields which are not "a", "b", or "c"
      recs-xform '\$r->prune("a", "b", "c")'
   Double records
      recs-xform --ret '\$r = [{\%\$r}, {\%\$r}]'
   Split the records on field a
      recs-xform --ret '[map { {%\$r, "a" => \$_} } split(/,/, delete(\$r->{"a"}))]'
USAGE
}

1;