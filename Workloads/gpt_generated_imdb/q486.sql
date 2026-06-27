SELECT
    title.title,
    title.production_year,
    MAX(CASE WHEN info_type.info = 'Genre' THEN movie_info.info END) AS genre,
    COUNT(DISTINCT cast_info.person_id) AS cast_count,
    COUNT(DISTINCT cast_info.person_role_id) AS character_count,
    COUNT(DISTINCT aka_name.id) AS aka_name_count
FROM cast_info
JOIN name
  ON cast_info.person_id = name.id
JOIN title
  ON cast_info.movie_id = title.id
LEFT JOIN aka_name
  ON aka_name.person_id = name.id
JOIN char_name
  ON cast_info.person_role_id = char_name.id
LEFT JOIN movie_info
  ON movie_info.movie_id = title.id
LEFT JOIN info_type
  ON movie_info.info_type_id = info_type.id
GROUP BY title.title, title.production_year
ORDER BY cast_count DESC
LIMIT 10
