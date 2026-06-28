class ExerciseVideo {
  final String youtubeId;
  final String title;
  final String titleIt; // 
  final String category;
  final int durationMinutes;

  ExerciseVideo({
    required this.youtubeId,
    required this.title,
    required this.titleIt,
    required this.category,
    required this.durationMinutes,
  });

  // Metodo helper per ottenere il titolo corretto in base alla lingua
  String getTitle(bool isItalian) {
    return isItalian ? titleIt : title;
  }
}

final List<ExerciseVideo> videoArchive = [
  
  // FULL BODY
  ExerciseVideo(
      youtubeId: 'pH6KMX0V7d0',
      title: 'Full Body Stretch 5 Min',
      titleIt: 'Stretching Total Body 5 Min',
      category: 'FULL BODY',
      durationMinutes: 5),
  ExerciseVideo(
      youtubeId: '7Ux--k7uwBY',
      title: '5 Min Work Stretch Break',
      titleIt: 'Pausa Stretching da Lavoro 5 Min',
      category: 'FULL BODY',
      durationMinutes: 5),
  ExerciseVideo(
      youtubeId: 'kdLSJuzRNUw',
      title: 'Desk Stretches Without Getting Up',
      titleIt: 'Stretching alla Scrivania (Senza Alzarsi)',
      category: 'FULL BODY',
      durationMinutes: 5),

  // NECK AND CERVICAL
  ExerciseVideo(
      youtubeId: 'was4RtzpfJs',
      title: 'Neck Pain Relief Stretches',
      titleIt: 'Stretching Allevia-Dolore per il Collo',
      category: 'NECK AND CERVICAL',
      durationMinutes: 5),
  ExerciseVideo(
      youtubeId: 'KL7H9R0i2n8',
      title: 'Neck & Shoulder Yoga Release',
      titleIt: 'Yoga Rilassante per Collo e Spalle',
      category: 'NECK AND CERVICAL',
      durationMinutes: 3),
  ExerciseVideo(
      youtubeId: 't-1Z2ZYpmt0',
      title: 'Physio Neck & Shoulder Routine',
      titleIt: 'Routine Fisioterapica Collo e Spalle',
      category: 'NECK AND CERVICAL',
      durationMinutes: 5),

  // BACK AND LUMBAR
  ExerciseVideo(
      youtubeId: 'UYMmtEFhuxA',
      title: 'Back Pain Relief Stretches',
      titleIt: 'Stretching Allevia-Dolore per la Schiena',
      category: 'BACK AND LUMBAR',
      durationMinutes: 5),
  ExerciseVideo(
      youtubeId: 'gjeBUnlHI3c',
      title: 'Lower Back Pain Relief 5 Min',
      titleIt: 'Sollievo per il Dolore Lombare 5 Min',
      category: 'BACK AND LUMBAR',
      durationMinutes: 5),

  // SHOULDERS AND UPPER BACK
  ExerciseVideo(
      youtubeId: '6lJBZCRlFnI',
      title: 'Shoulder & Neck Desk Stretch',
      titleIt: 'Stretching Spalle e Collo alla Scrivania',
      category: 'SHOULDERS AND UPPER BACK',
      durationMinutes: 5),
  ExerciseVideo(
      youtubeId: 'vLPfP1oRJFM',
      title: 'Neck and Shoulders 4 Min Yoga',
      titleIt: 'Yoga Collo e Spalle 4 Min',
      category: 'SHOULDERS AND UPPER BACK',
      durationMinutes: 4),
  ExerciseVideo(
      youtubeId: 'sDS5KQssV0g',
      title: 'Postural Exercises for Back and Shoulders',
      titleIt: 'Esercizi Posturali Schiena E Spalle',
      category: 'SHOULDERS AND UPPER BACK',
      durationMinutes: 15),

  // ARMS AND ELBOWS
  ExerciseVideo(
    youtubeId: 'kfP_9z-BtmA', 
    title: '5 min toned arms workout',
    titleIt: 'Allenamento per braccia toniche in 5 minuti',
    category: 'ARMS AND ELBOWS',
    durationMinutes: 5),
  ExerciseVideo(
    youtubeId: 'HOtUvGF9T-M', 
    title: 'Arms workout at home',
    titleIt: 'Allenamento per le braccia a casa',
    category: 'ARMS AND ELBOWS',
    durationMinutes: 3),
   ExerciseVideo(
    youtubeId: 'vsCOaffOo4g', 
    title: '10 easy arm moves you can do sitting down!',
    titleIt: '10 semplici esercizi per le braccia che puoi fare da seduto!',
    category: 'ARMS AND ELBOWS',
    durationMinutes: 10),

  // WRISTS AND HANDS
  ExerciseVideo(
    youtubeId: 'XKWJ3Flfm8A', 
    title: '10 Minute Wrist Stretching and Mobility workout',
    titleIt: 'Allenamento di 10 minuti per lo stretching e la mobilità dei polsi',
    category: 'WRISTS AND HANDS',
    durationMinutes: 10),
  ExerciseVideo(
    youtubeId: 'ZQnAO1DhLEA', 
    title: 'Yoga to strengthen the wrist',
    titleIt: 'Yoga per rafforzare il polso',
    category: 'WRISTS AND HANDS',
    durationMinutes: 5),

  // LEGS AND ANKLES
  ExerciseVideo(
    youtubeId: 'z4uaQIfNNZw', 
    title: '10 - Minute Seated Leg Workout',
    titleIt: 'Allenamento 10 Minuti per le gambe da seduti',
    category: 'LEGS AND ANKLES',
    durationMinutes: 10),
  ExerciseVideo(
    youtubeId: 'ZYosnA-1_W0', 
    title: 'How to strengthen your ankles at home',
    titleIt: 'Come rafforzare le caviglie a casa',
    category: 'LEGS AND ANKLES',
    durationMinutes: 10),
  ExerciseVideo(
    youtubeId: 'cGCxjdb1S2Q', 
    title: '5-Minute Seated Exercises for Stronger Legs!',
    titleIt: 'Esercizi da seduti di 5 minuti per gambe più forti!',
    category: 'LEGS AND ANKLES',
    durationMinutes: 5),

  ];