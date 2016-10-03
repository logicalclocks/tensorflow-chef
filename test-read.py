#!/usr/bin/env python
from __future__ import print_function
import numpy as np
import tensorflow as tf
import math as math

def file_len(fname):
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1

def read_from_csv(filename_queue):
  reader = tf.TextLineReader(skip_header_lines=1)
  _, csv_row = reader.read(filename_queue)
  record_defaults = [[0],[0],[0],[0],[0]]
  colHour,colQuarter,colAction,colUser,colLabel = tf.decode_csv(csv_row, record_defaults=record_defaults)
  features = tf.pack([colHour,colQuarter,colAction,colUser])
  label = tf.pack([colLabel])
  return features, label

def input_pipeline(batch_size, num_epochs=None):
  # filename_queue = tf.train.string_input_producer(["/srv/zeppelin/tf.csv"], num_epochs=num_epochs, shuffle=True)
  filename_queue = tf.train.string_input_producer(["hdfs://10.0.2.15:8020/Projects/tf/Resources/tf.csv"])
  example, label = read_from_csv(filename_queue)
  min_after_dequeue = 10000
  capacity = min_after_dequeue + 3 * batch_size
  example_batch, label_batch = tf.train.shuffle_batch(
      [example, label], batch_size=batch_size, capacity=capacity,
      min_after_dequeue=min_after_dequeue)
  return example_batch, label_batch

file_length = file_len("/srv/zeppelin/tf.csv") - 1

examples, labels = input_pipeline(file_length, 1)

with tf.Session() as sess:
  tf.initialize_all_variables().run()

  coord = tf.train.Coordinator()
  threads = tf.train.start_queue_runners(coord=coord)

  try:
    while not coord.should_stop():
      example_batch, label_batch = sess.run([examples, labels])
      print(example_batch)
  except tf.errors.OutOfRangeError:
    print('Done training, epoch reached')
  finally:
    coord.request_stop()

  coord.join(threads)

