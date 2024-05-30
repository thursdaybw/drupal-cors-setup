<?php

use Drupal\consumers\Entity\Consumer;

/**
 * Create a new OAuth consumer programmatically.
 */
function create_oauth_consumer() {
  // Define the consumer properties.
  $consumer_values = [
    'label' => 'My OAuth Consumer',
    'uid' => 1, // User ID of the consumer owner.
    'secret' => 'your-client-secret', // This should be securely hashed.
    'roles' => ['authenticated'], // Roles assigned to the consumer.
    'status' => 1, // Enable the consumer.
    'client_id' => 'your-client-id', // Add the client_id field.
  ];

  // Create the consumer entity.
  $consumer = Consumer::create($consumer_values);

  // Save the consumer entity.
  $consumer->save();

  // Return the created consumer.
  return $consumer;
}

// Call the function to create a new consumer.
$new_consumer = create_oauth_consumer();

