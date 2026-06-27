WITH person_gender_info AS (
  SELECT
    it.id AS info_type_id,
    it.info AS info_type,
    n.gender AS gender,
    COUNT(DISTINCT pi.person_id) AS person_cnt
  FROM info_type it
  JOIN person_info pi ON pi.info_type_id = it.id
  JOIN name n ON n.id = pi.person_id
  GROUP BY it.id, it.info, n.gender
),
cast_movie_counts AS (
  SELECT
    it.id AS info_type_id,
    n.gender AS gender,
    COUNT(DISTINCT ci.movie_id) AS cast_movie_cnt
  FROM info_type it
  JOIN person_info pi ON pi.info_type_id = it.id
  JOIN name n ON n.id = pi.person_id
  JOIN cast_info ci ON ci.person_id = n.id
  GROUP BY it.id, n.gender
),
aka_name_counts AS (
  SELECT
    it.id AS info_type_id,
    n.gender AS gender,
    COUNT(DISTINCT an.name) AS alt_name_cnt
  FROM info_type it
  JOIN person_info pi ON pi.info_type_id = it.id
  JOIN name n ON n.id = pi.person_id
  JOIN aka_name an ON an.person_id = n.id
  GROUP BY it.id, n.gender
),
movie_info_counts AS (
  SELECT
    it.id AS info_type_id,
    COUNT(DISTINCT mi.movie_id) AS movie_info_cnt
  FROM info_type it
  JOIN movie_info mi ON mi.info_type_id = it.id
  GROUP BY it.id
)
SELECT
  pgi.info_type_id,
  pgi.info_type,
  pgi.gender,
  pgi.person_cnt,
  COALESCE(cmc.cast_movie_cnt, 0) AS cast_movie_cnt,
  COALESCE(anc.alt_name_cnt, 0) AS alt_name_cnt,
  COALESCE(mic.movie_info_cnt, 0) AS movie_info_cnt
FROM person_gender_info pgi
LEFT JOIN cast_movie_counts cmc
  ON cmc.info_type_id = pgi.info_type_id AND cmc.gender = pgi.gender
LEFT JOIN aka_name_counts anc
  ON anc.info_type_id = pgi.info_type_id AND anc.gender = pgi.gender
LEFT JOIN movie_info_counts mic
  ON mic.info_type_id = pgi.info_type_id
ORDER BY pgi.info_type_id, pgi.gender
