enum ERepresentations {
  Full,
  Large,
  Medium,
  Small,
  Thumb,
  ThumbSmall,
  ThumbTiny
}

ERepresentations representationFromWidth(int width) {
  if (width <= 50)   return ERepresentations.ThumbTiny;
  if (width <= 150)  return ERepresentations.ThumbSmall;
  if (width <= 250)  return ERepresentations.Thumb;
  if (width <= 320)  return ERepresentations.Small;
  if (width <= 800)  return ERepresentations.Medium;
  if (width <= 1280) return ERepresentations.Large;
  return ERepresentations.Full;
}