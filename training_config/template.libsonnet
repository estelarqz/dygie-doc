{
  DyGIE: {
    local dygie = self,

    // Mapping from target task to the metric used to assess performance on that task.
    local validation_metrics = {
      'ner': '+ner_f1',
      'rel': '+rel_f1',
      'coref': '+coref_f1',
      'events': 'arg_class_f1'
    },

    ////////////////////

    // REQUIRED VALUES. Must be set by child class.

    // Paths to train, dev, and test data.
    data_paths :: error 'Must override `data_paths`',

    // Weights on the losses of the model components (e.g. NER, relation, etc).
    loss_weights :: error 'Must override `loss_weights`',

    // Make early stopping decisions based on performance for this task.
    // Options are: `['ner', 'rel', 'coref': 'events']`
    target_task :: error 'Must override `target_task`',

    // DEFAULT VALUES. May be set by child class..
    bert_model :: 'bert-base-cased',
    max_span_width :: 8,
    cuda_device :: -1,

    ////////////////////

    // All remaining values can be overridden using the `:+` mechanism
    // described in `doc/config.md`
    random_seed: 13370,
    numpy_seed: 1337,
    pytorch_seed: 133,
    dataset_reader: {
      type: 'dygie',
      token_indexers: {
        bert: {
          type: 'pretrained_transformer_mismatched',
          model_name: dygie.bert_model,
        },
      },
      max_span_width: dygie.max_span_width,
      cache_directory: 'cache',
    },
    train_data_path: dygie.data_paths.train,
    validation_data_path: dygie.data_paths.validation,
    test_data_path: dygie.data_paths.test,
    // If provided, use pre-defined vocabulary. Else compute on the fly.
    model: {
      type: 'dygie',
      text_field_embedder: {
        token_embedders: {
          bert: {
            type: 'pretrained_transformer_mismatched',
            model_name: dygie.bert_model,
          },
        },
      },
      initializer: {  // Initializer for shared span representations.
        regexes:
          [['_span_width_embedding.weight', { type: 'xavier_normal' }]],
      },
      module_initializer: {  // Initializer for component module weights.
        regexes:
          [
            ['.*weight', { type: 'xavier_normal' }],
            ['.*weight_matrix', { type: 'xavier_normal' }],
          ],
      },
      loss_weights: dygie.loss_weights,
      feature_size: 20,
      max_span_width: dygie.max_span_width,
      target_task: dygie.target_task,
      feedforward_params: {
        num_layers: 2,
        hidden_dims: 150,
        dropout: 0.4,
      },
      modules: {
        coref: {
          spans_per_word: 0.3,
          max_antecedents: 100,
          coref_prop: 0,
        },
        ner: {},
        relation: {
          spans_per_word: 0.5,
        },
        events: {
          trigger_spans_per_word: 0.3,
          argument_spans_per_word: 0.8,
          loss_weights: {
            trigger: 1.0,
            arguments: 1.0,
          },
        },
      },
    },
    data_loader: {
      type: 'ie_batch',
      batch_size: 1,
    },
    trainer: {
      checkpointer: {
        num_serialized_models_to_keep: 3,
      },
      num_epochs: 25,
      grad_norm: 5.0,
      patience: 5,
      cuda_device: dygie.cuda_device,
      validation_metric: validation_metrics[dygie.target_task],
      optimizer: {
        type: 'adamw',
        lr: 1e-3,
        weight_decay: 0.0,
        parameter_groups: [
          [
            ['_text_field_embedder'],
            {
              lr: 5e-5,
              weight_decay: 0.01,
              finetune: true,
            },
          ],
        ],
      },
    },
  },
}
