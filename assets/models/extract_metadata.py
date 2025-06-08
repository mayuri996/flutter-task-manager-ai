from tflite_support import metadata as _metadata

# Path to your .tflite model
model_path = "mobilebert.tflite"

try:
    # Load the model and its metadata
    displayer = _metadata.MetadataDisplayer.with_model_file(model_path)

    # Extract associated files (vocab.txt and labels.txt)
    vocab_file = displayer.get_associated_file("vocab.txt")
    labels_file = displayer.get_associated_file("labels.txt")

    # Save vocab.txt if found
    if vocab_file:
        with open("vocab.txt", "wb") as f:
            f.write(vocab_file)
        print("Successfully extracted vocab.txt")
    else:
        print("vocab.txt not found in model metadata")

    # Save labels.txt if found
    if labels_file:
        with open("labels.txt", "wb") as f:
            f.write(labels_file)
        print("Successfully extracted labels.txt")
    else:
        print("labels.txt not found in model metadata")

except Exception as e:
    print(f"Error extracting metadata: {e}")