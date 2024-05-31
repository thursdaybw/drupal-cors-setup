<?php
/**
 * Creates a node of type 'article' in Drupal.
 * Usage: drush scr path/to/create-article.php
 */

use Drupal\node\Entity\Node;

// Create a new article node with title and body.
$node = Node::create([
  'type' => 'article',
  'title' => 'Demo Article',
  'body' => [
    'value' => 'This article is created to demonstrate the setup and usage of nodes via Drupal API.',
    'format' => 'full_html',
  ],
  'status' => 1, // Published
]);

// Save the node.
$node->save();

echo "Article created with nid: " . $node->id() . "\n";

