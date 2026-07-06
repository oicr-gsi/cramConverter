version 1.0

workflow cramConverter {
  input {
    File inputAlign
    Boolean isBam
    String outputFileNamePrefix = "output"
  }

  if (isBam) {
    call bamToCram {
      input:
        inputBam = inputAlign,
        outputFileNamePrefix = outputFileNamePrefix

    }
  }
  if (!isBam) {
    call cramToBam {
      input:
        inputCram = inputAlign,
        outputFileNamePrefix = outputFileNamePrefix
    }
  }

   output {
        File outputAlign = select_first([bamToCram.outputCram, cramToBam.outputBam])
        File outputIndex = select_first([bamToCram.outputCramIndex, cramToBam.outputBamIndex])
    }


  parameter_meta {
    inputAlign: "input alignment file that will be converted to cram or bam file"
    isBam: "is the input a bam"
    outputFileNamePrefix: "Prefix for output file"
  }

  meta {
    author: "Xuemei Luo"
    email: "xuemei.luo@oicr.on.ca"
    description: "Workflow for converting cram to bam or bam to cram"
    dependencies:
    [
      {
      name: "samtools/1.9",
      url: "https://github.com/samtools/samtools"
      }
    ]
    output_meta: {
    outputAlign: {
        description: "output alignment file",
        vidarr_label: "outputAlign"
    },
    outputIndex: {
        description: "output alignment index file",
        vidarr_label: "outputIndex"
    }
}
  }
}


task bamToCram {
  input{
    File inputBam
    String outputFileNamePrefix
    Int jobMemory = 12
    Int threads = 4
    Int timeout = 8
    String referenceFasta = "$HG38_ROOT/hg38_random.fa"
    String? addParam
    String modules="samtools/1.9 hg38/p12"   
  }
  String resultCram = "~{outputFileNamePrefix}.cram"
  String resultCramIndex = "~{outputFileNamePrefix}.crai"

  command <<<
    set -euo pipefail
    #convert bam to cram
    samtools view -C -T ~{referenceFasta} --threads ~{threads} ~{addParam} -o ~{resultCram} ~{inputBam}
    # index cram
    samtools index -@ ~{threads} ~{resultCram} ~{resultCramIndex}
  >>>

  runtime {
    memory: "~{jobMemory}G"
    cpu: "~{threads}"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  output {
    File outputCram = "~{resultCram}"
    File outputCramIndex = "~{resultCramIndex}"
  }

  parameter_meta {
    inputBam: "Input bam file"
    outputFileNamePrefix: "Output prefix to prefix output file names with"
    jobMemory: "Memory (in GB) to allocate to the job"
    threads: "Requested CPU threads"
    referenceFasta: "The fasta that is being used as a refrence to build the cram file"
    modules: "Modules required to process this step"
    timeout: "Hours before task timeout"
    addParam: "additional parameters"
  }

  meta {
    output_meta: {
      outputCram: "Converted cram file",
      outputCramIndex: "Index of the Converted CRAM file"
    }
  }
}

task cramToBam {
  input{
    File inputCram
    String outputFileNamePrefix
    Int jobMemory = 12
    Int threads = 4
    Int timeout = 5
    String referenceFasta = "$HG38_ROOT/hg38_random.fa"
    String? addParam
    String modules="samtools/1.9 hg38/p12"
  }

  String resultBam = "~{outputFileNamePrefix}.bam"
  String resultBamIndex = "~{outputFileNamePrefix}.bai"

  command <<<
    set -euo pipefail

    #convert cram to bam
    samtools view -b -T ~{referenceFasta} --threads ~{threads} ~{addParam} -o ~{resultBam} ~{inputCram}

    # index bam
    samtools index  -@ ~{threads} ~{resultBam} ~{resultBamIndex}


  >>>

  runtime {
    memory: "~{jobMemory}G"
    cpu: "~{threads}"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  output {
    File outputBam = "~{resultBam}"
    File outputBamIndex = "~{resultBamIndex}"
  }

  parameter_meta {
    inputCram: "Input Cram file"
    outputFileNamePrefix: "Output prefix to prefix output file names with"
    jobMemory: "Memory (in GB) to allocate to the job"
    threads: "Requested CPU threads"
    referenceFasta: "The fasta that is being used as a refrence to build the bam file"
    modules: "Modules required to process this step"
    timeout: "Hours before task timeout"
    addParam: "additional parameters"
  }

  meta {
    output_meta: {
      outputBam: "Converted BAM file",
      outputBamIndex: "Index of the Converted BAM file"
    }
  }
}
