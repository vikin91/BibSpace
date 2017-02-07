package IHtmlBibtexConverter;
use feature qw(current_sub);
use Moose::Role;

requires 'set_template'; # e.g., bst file
requires 'convert';
requires 'get_html';
requires 'get_warnings';

no Moose;
1;