local template = import "template.libsonnet";

template.DyGIE {
  bert_model: "allenai/longformer-base-4096",
  cuda_device: 3,
  data_paths: {
    train: "data/cdr/processed-data/train.json",
    validation: "data/cdr/processed-data/dev.json",
    test: "data/cdr/processed-data/test.json",
  },
  loss_weights: {
    ner: 0.2,
    relation: 0.0,
    coref: 1.0,
    events: 0.0,
    document_relation: 1.0,
    document_events:0.0,
    event_coref: 0.0,

  },
  target_task: "document_relation",
  encode_document: true,
  window_size: 15,
  gradient_checkpointing:true
}