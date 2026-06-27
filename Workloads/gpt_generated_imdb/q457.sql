WITH person_movie_stats AS (
  SELECT
    n.id AS person_id,
    n.name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT cn.id) AS distinct_character_count,
    MIN(t.production_year) AS first_movie_year,
    MAX(t.production_year) AS last_movie_year
  FROM name n
  JOIN cast_info ci ON ci.person_id = n.id
  JOIN title t ON t.id = ci.movie_id
  LEFT JOIN char_name cn ON cn.id = ci.person_role_id
  GROUP BY n.id, n.name, n.gender
  HAVING COUNT(DISTINCT ci.movie_id) >= 5
),
person_alt_name_counts AS (
  SELECT
    an.person_id,
    COUNT(*) AS alt_name_count
  FROM aka_name an
  GROUP BY an.person_id
),
person_info_summary AS (
  SELECT
    pi.person_id,
    COUNT(*) AS total_info_entries,
    SUM(CASE WHEN it.info = 'birth date' THEN 1 ELSE 0 END) AS birth_date_entries
  FROM person_info pi
  JOIN info_type it ON it.id = pi.info_type_id
  GROUP BY pi.person_id
)
SELECT
  pms.person_id,
  pms.name,
  pms.gender,
  pms.movie_count,
  pms.distinct_character_count,
  pms.first_movie_year,
  pms.last_movie_year,
  COALESCE(panc.alt_name_count, 0) AS alt_name_count,
  COALESCE(pis.total_info_entries, 0) AS total_info_entries,
  COALESCE(pis.birth_date_entries, 0) AS birth_date_entries
FROM person_movie_stats pms
LEFT JOIN person_alt_name_counts panc ON panc.person_id = pms.person_id
LEFT JOIN person_info_summary pis ON pis.person_id = pms.person_id
ORDER BY pms.movie_count DESC
LIMIT 20
