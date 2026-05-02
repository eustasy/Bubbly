<?php

$finder = PhpCsFixer\Finder::create()
    ->exclude('vendor')
    ->in(__DIR__ . '/../..');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12'                        => true,
        '@PHP83Migration'               => true,
        'array_syntax'                  => ['syntax' => 'short'],
        'ordered_imports'               => ['sort_algorithm' => 'alpha'],
        'no_unused_imports'             => true,
        'not_operator_with_successor_space' => true,
        'trailing_comma_in_multiline'   => ['elements' => ['arrays', 'arguments', 'parameters']],
        'phpdoc_scalar'                 => true,
        'unary_operator_spaces'         => true,
        'binary_operator_spaces'        => true,
        'blank_line_before_statement'   => ['statements' => ['return']],
        'single_quote'                  => true,
    ])
    ->setFinder($finder);
