
#
# bioperl module for Bio::PrimarySeq
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::PrimarySeq - Bioperl lightweight Sequence Object

=head1 SYNOPSIS

  # The Bio::SeqIO for file reading, Bio::DB::GenBank for
  # database reading
  use Bio::Seq;
  use Bio::SeqIO;
  use Bio::DB::GenBank;

  #make from memory
  $seqobj = Bio::PrimaySeq->new ( -seq => 'ATGGGGTGGGCGGTGGGTGGTTTG',
			    -id  => 'GeneFragment-12',
			    -accession => 'X78121',
			    -moltype => 'dna'
			    );
  
  # read from file
  $inputstream = Bio::SeqIO->new(-file => "myseq.fa",-format => 'Fasta');
  $seqobj = $inputstream->next_seq();

  # get from database
  $db = Bio::DB::GenBank->new();
  $seqobj = $db->get_Seq_by_acc('X78121');

  # to get out parts of the sequence.

  print "Sequence ", $seqobj->id(), " with accession ", $seqobj->accession, " and desc ", $seqobj->desc, "\n";

  $string  = $seqobj->seq();
  $string2 = $seqobj->subseq(1,40);

  

=head1 DESCRIPTION

PrimaySeq is a lightweight Sequence object, storing little more than
the sequence, its name, a computer useful unique name. It does not
contain sequence features or other information.  To have a sequence
with sequence features you should use the Seq object which uses this
object.

Sequence objects are defined by the Bio::PrimarySeqI interface, and this
object is a pure Perl implementation of the interface (if that's
gibberish to you, don't worry. The take home message is that this
object is the bioperl default sequence object, but other people can
use their own objects as sequences if they so wish). If you are
interested in wrapping your own objects as compliant Bioperl sequence
objects, then you should read the Bio::PrimarySeqI documentation

The documenation of this object is a merge of the Bio::PrimarySeq and
Bio::PrimarySeqI documentation.  This allows all the methods which you can
call on sequence objects here.

=head1 Reimplementation

The Sequence object was completely rewritten for the 0.6 series. This
was because the old Sequence object was becoming heavily bloated and
difficult to maintain. There are some key changes from the old object
to the new object, but basically, everything should work with the new
object with a minimal number of changes.

The key change is that the format IO has been removed from this object
and moved to the Bio::SeqIO system, which provides a much better way
to encapsulate the sequence format reading. Please read the SeqIO
documentation, but the take home message is that lines like

    # old style reading from files
    $seq = Bio::Seq->new( -file => "myfile");

Becomes

    # new style reading from files.
    $inputstream = Bio::SeqIO->new( -file => "myfile", -format => 'Fasta');
    $seqobj = $inputstream->next_seq();

For writing files, a similar system is used

     # old style writing to files
     print OUTPUT $seq->layout_fasta;

     # new style writing to files
     $outputstream = Bio::SeqIO->new( -fh => \*OUTPUT, -format => 'Fasta');
     $outputstream->write_seq($seqobj);

=head2 Deprecated methods

A number of methods which were present in the old 0.04/0.05 series
have been deprecated.  Most of these methods work as before, but
provide a warning that someone has called a deprecated method.

=over 

=item getseq - use seq/subseq instead

=item str - use seq/subseq instead

=item ary - use seq/subseq with your own split afterwards

=item type - use moltype, but notice that moltype returns different values (lowercase)

=back

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  vsns-bcd-perl@lists.uni-bielefeld.de          - General discussion
  vsns-bcd-perl-guts@lists.uni-bielefeld.de     - Technically-oriented discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.  Bug reports can be submitted via
 email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney

Email birney@sanger.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::PrimarySeq;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Object

use Bio::Root::Object;
use Bio::PrimarySeqI;


@ISA = qw(Bio::Root::Object Bio::PrimarySeqI);

# new() is inherited from Bio::Root::Object

# _initialize is where the heavy stuff will happen when new is called

sub _initialize {
  my($self,@args) = @_;

  my($seq,$id,$acc,$pid,$desc,$moltype,$given_id) =
      $self->_rearrange([qw(SEQ
			    DISPLAY_ID
			    ACCESSION_NUMBER
			    PRIMARY_ID
			    DESC
			    MOLTYPE
                            ID
			    )],
			@args);

  

  my $make = $self->SUPER::_initialize(@args);

  if( defined $id && defined $given_id ) {
      if( $id ne $given_id ) {
	  $self->throw("Provided both id and display_id constructor functions. [$id] [$given_id]");
      }
  }
  if( defined $given_id ) { $id = $given_id; }

  $seq     && $self->seq($seq);
  $id      && $self->display_id($id);
  $acc     && $self->accession_number($acc);
  $pid     && $self->primary_id($pid);
  $desc    && $self->desc($desc);
  $moltype && $self->moltype($moltype);

# set stuff in self from @args
  return $make; # success - we hope!
}

=head2 seq

 Title   : seq
 Usage   : $string    = $obj->seq()
 Function: Returns the sequence as a string of letters. The
           case of the letters is left up to the implementer.
           Suggested cases are upper case for proteins and lower case for
           DNA sequence (IUPAC standard), but you should not rely on this
 Returns : A scalar

=cut

sub seq {
   my ($obj,$value) = @_;
   if( defined $value) {
       if( $value !~ /^[A-Za-z\-\.\*]+$/ ) {
	   $obj->throw("Attempting to set the sequence to [$value] which does not look healthy");
       }
       $obj->{'seq'} = $value;
       $obj->_guess_type();
    }
   my $v = $obj->{'seq'};
   return $obj->{'seq'};
}

=head2 subseq

 Title   : subseq
 Usage   : $substring = $obj->subseq(10,40);
 Function: returns the subseq from start to end, where the first base
           is 1 and the number is inclusive, ie 1-2 are the first two
           bases of the sequence
 Returns : a string
 Args    :


=cut

sub subseq {
   my ($self,$start,$end) = @_;

   if( $start > $end ){
       $self->throw("in subseq, start [$start] has to be greater than end [$end]");
   }

   # remove one from start, and then length is end-start

   $start--;

   return substr $self->seq, $start, ($end-$start);

}

=head2 display_id

 Title   : display_id
 Usage   : $id_string = $obj->display_id();
 Function: returns the display id, aka the common name of the Sequence object.
           
         The semantics of this is that it is the most likely string to be
         used as an identifier of the sequence, and likely to have "human" readability.
         The id is equivalent to the ID field of the GenBank/EMBL databanks and
         the id field of the Swissprot/sptrembl database. In fasta format, the >(\S+)
         is presumed to be the id, though some people overload the id to embed other 
         information. Bioperl does not use any embedded information in the ID field,
         and people are encouraged to use other mechanisms (accession field for example,
         or extending the sequence object) to solve this. 

 Returns : A string
 Args    : None


=cut

sub display_id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'display_id'} = $value;
    }
    return $obj->{'display_id'};

}


=head2 accession_number

 Title   : accession_number
 Usage   : $unique_key = $obj->accession_number;
 Function: Returns the unique biological id for a sequence, commonly
           called the accession_number. For sequences from established
           databases, the implementors should try to use the correct
           accession number. Notice that primary_id() provides the
           unique id for the implemetation, allowing multiple objects
           to have the same accession number in a particular implementation.

           For sequences with no accession number, this method should return
           "unknown".  
 Returns : A string
 Args    : A string (optional) for setting

=cut

sub accession_number {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'accession_number'} = $value;
  }
   if( ! exists $obj->{'accession_number'} ) {
       return "unknown";
   } 
   return $obj->{'accession_number'};

}


=head2 primary_id

 Title   : primary_id
 Usage   : $unique_key = $obj->primary_id;
 Function: Returns the unique id for this object in this
           implementation. This allows implementations to manage
           their own object ids in a way the implementaiton can control
           clients can expect one id to map to one object.

           For sequences with no natural primary id, this method should return
           a stringified memory location.
 Returns : A string
 Args    : A string (optional, for setting)

=cut

sub primary_id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'primary_id'} = $value;
    }
   if( ! exists $obj->{'primary_id'} ) {
       return "$obj";
   }
   return $obj->{'primary_id'};

}


=head2 moltype

 Title   : moltype
 Usage   : if( $obj->moltype eq 'dna' ) { /Do Something/ }
 Function: Returns the type of sequence being one of 
           'dna', 'rna' or 'protein'. This is case sensitive.

           This is not called <type> because this would cause
           upgrade problems from the 0.5 and earlier Seq objects.
           
 Returns : a string either 'dna','rna','protein'. NB - the object must
           make a call of the type - if there is no type specified it
           has to guess.
 Args    : none


=cut

BEGIN {
    my %valid_type = map {$_, 1} qw( dna rna protein );

    sub moltype {
       my ($obj,$value) = @_;
       if (defined $value) {
           unless ( $valid_type{$value} ) {
	       $obj->throw("Molecular type '$value' is not a valid type (".
                  join(',', map "'$_'", sort keys %valid_type) .") lowercase");
           }
           $obj->{'moltype'} = $value;
       }
       return $obj->{'moltype'};

    }
}

=head2 desc

 Title   : desc
 Usage   : $obj->desc($newval)
 Function: 
 Example : 
 Returns : value of desc
 Args    : newvalue (optional)


=cut

sub desc {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'desc'} = $value;
    }
    return $obj->{'desc'};

}

=head2 can_call_new

 Title   : can_call_new
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub can_call_new {
   my ($self) = @_;

   return 1;

}

=head1 Methods Inherieted from Bio::PrimarySeqI

These methods are available on Bio::PrimarySeq, although they are actually
implemented on Bio::PrimarySeqI

=head2 revcom

 Title   : revcom
 Usage   : $rev = $seq->revcom()
 Function: Produces a new Bio::SeqI implementing object which
           is the reversed complement of the sequence. For protein
           sequences this throws an exception of 
           "Sequence is a protein. Cannot revcom"

           The id is the same id as the orginal sequence, and the
           accession number is also indentical. If someone wants to
           track that this sequence has be reversed, it needs to
           define its own extensions

           To do an inplace edit of an object you can go:
   
           $seqobj = $seqobj->revcom();

           This of course, causes Perl to handle the garbage
           collection of the old object, but it is roughly speaking as
           efficient as an inplace edit.

 Returns : A new (fresh) Bio::SeqI object
 Args    : none

=cut

=head2 trunc

 Title   : trunc
 Usage   : $subseq = $myseq->trunc(10,100);
 Function: Provides a truncation of a sequence,
           
 Example :
 Returns : a fresh Bio::SeqI implementing object
 Args    :


=cut

=head1 Internal methods

These are internal methods to PrimarySeq

=cut

=head2 _guess_type

 Title   : _guess_type
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub _guess_type {
   my ($self) = @_;
   my ($str,$str2,$total,$atgc,$u,$type);

   $str = $self->seq();
   $str =~ s/\-\.//g;

   $total = CORE::length($str);
   if( $total == 0 ) {
       $self->throw("Got a sequence with no letters in - cannot guess type [$str]");
   }

   $str2 = $str;

   $str2 =~ s/[ATGCNatgcn]//g;
   $atgc = $total - CORE::length $str2;
   $str = $str2;
   $str2 =~ s/Uu//g;
   
   $u = CORE::length($str) - CORE::length($str2);


   if( ($atgc / $total) > 0.85 ) {
       $type = 'dna';
   } elsif( (($atgc + $u) / $total) > 0.85 ) {
       $type = 'rna';
   } else {
       $type = 'protein';
   }
   
   $self->moltype($type);

}



1;












