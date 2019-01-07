=head1 LICENSE

Copyright [1999-2019] EMBL-European Bioinformatics Institute
and Wellcome Trust Sanger Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=pod

=head1 NAME

Bio::EnsEMBL::EGPipeline::PipeConfig::VariationMartTidy_conf

=head1 DESCRIPTION

Tidy up after creating a variation mart, i.e. remove MTMP tables from
variation databases.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::PipeConfig::VariationMartTidy_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::EnsemblGeneric_conf');

sub default_options {
  my ($self) = @_;
  return {
    %{$self->SUPER::default_options},
    
    pipeline_name => 'variation_mart_tidy_'.$self->o('ensembl_release'),
    
    species      => [],
    antispecies  => [],
    division     => [],
    run_all      => 0,
  };
}

# Force an automatic loading of the registry in all workers.
sub beekeeper_extra_cmdline_options {
  my $self = shift;
  return "-reg_conf ".$self->o("registry");
}

# Ensures that species output parameter gets propagated implicitly.
sub hive_meta_table {
  my ($self) = @_;
  
  return {
    %{$self->SUPER::hive_meta_table},
    'hive_use_param_stack'  => 1,
  };
}

sub pipeline_analyses {
  my ($self) = @_;
  
  return [
    {
      -logic_name      => 'ScheduleSpeciesForDropMTMP',
      -module          => 'Bio::EnsEMBL::Production::Pipeline::BaseSpeciesFactory',
      -input_ids       => [ {} ],
      -parameters      => {
                            species     => $self->o('species'),
                            antispecies => $self->o('antispecies'),
                            division    => $self->o('division'),
                            run_all     => $self->o('run_all'),
                          },
      -max_retry_count => 0,
      -rc_name         => 'normal',
      -flow_into       => {
                            '4' => 'DropMTMPTables'
                          }
    },

    {
      -logic_name        => 'DropMTMPTables',
      -module            => 'Bio::EnsEMBL::EGPipeline::VariationMart::DropMTMPTables',
      -parameters        => {},
      -max_retry_count   => 0,
      -rc_name           => 'normal'
    },
    
  ];
}

sub resource_classes {
  my ($self) = @_;
  return {
    'default'           => {'LSF' => '-q production-rh7 -M  4000 -R "rusage[mem=4000]"'},
    'normal'            => {'LSF' => '-q production-rh7 -M  4000 -R "rusage[mem=4000]"'},
    '8Gb_mem'           => {'LSF' => '-q production-rh7 -M  8000 -R "rusage[mem=8000]"'},
    '16Gb_mem_16Gb_tmp' => {'LSF' => '-q production-rh7 -M 16000 -R "rusage[mem=16000,tmp=16000]"'},
  }
}

1;
