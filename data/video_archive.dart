class ExerciseVideo {
  final String youtubeId;
  final String title;
  final String category;
  final int durationMinutes;

  ExerciseVideo({
    required this.youtubeId,
    required this.title,
    required this.category,
    required this.durationMinutes,
  });
}

final List<ExerciseVideo> videoArchive = [
  // FULL BODY
  ExerciseVideo(youtubeId: 'pH6KMX0V7d0', title: 'Full Body Stretch 5 Min', category: 'FULL BODY', durationMinutes: 5),
  ExerciseVideo(youtubeId: '7Ux--k7uwBY', title: '5 Min Work Stretch Break', category: 'FULL BODY', durationMinutes: 5),
  ExerciseVideo(youtubeId: 'kdLSJuzRNUw', title: 'Desk Stretches Without Getting Up', category: 'FULL BODY', durationMinutes: 5),

  // NECK AND CERVICAL
  ExerciseVideo(youtubeId: 'was4RtzpfJs', title: 'Neck Pain Relief Stretches', category: 'NECK AND CERVICAL', durationMinutes: 5),
  ExerciseVideo(youtubeId: 'KL7H9R0i2n8', title: 'Neck & Shoulder Yoga Release', category: 'NECK AND CERVICAL', durationMinutes: 3),
  ExerciseVideo(youtubeId: 't-1Z2ZYpmt0', title: 'Physio Neck & Shoulder Routine', category: 'NECK AND CERVICAL', durationMinutes: 5),

  // BACK AND LUMBAR
  ExerciseVideo(youtubeId: 'UYMmtEFhuxA', title: 'Back Pain Relief Stretches', category: 'BACK AND LUMBAR', durationMinutes: 5),
  ExerciseVideo(youtubeId: 'gjeBUnlHI3c', title: 'Lower Back Pain Relief 5 Min', category: 'BACK AND LUMBAR', durationMinutes: 5),

  // SHOULDERS AND UPPER BACK
  ExerciseVideo(youtubeId: '6lJBZCRlFnI', title: 'Shoulder & Neck Desk Stretch', category: 'SHOULDERS AND UPPER BACK', durationMinutes: 5),
  ExerciseVideo(youtubeId: 'vLPfP1oRJFM', title: 'Neck and Shoulders 4 Min Yoga', category: 'SHOULDERS AND UPPER BACK', durationMinutes: 4),
];