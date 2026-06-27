WITH cast_agg AS (
  SELECT 
    ci.movie_id,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT CASE WHEN it.info = 'award' THEN ci.person_id END) AS award_cast,
    COUNT(DISTINCT cn.id) AS role_count
  FROM cast_info ci
  LEFT JOIN char_name cn ON ci.person_role_id = cn.id
  LEFT JOIN name n ON ci.person_id = n.id
  LEFT JOIN person_info pi ON pi.person_id = n.id
  LEFT JOIN info_type it ON pi.info_type_id = it.id
  GROUP BY ci.movie_id
),
keyword_agg AS (
  SELECT 
    mk.movie_id,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
  FROM movie_keyword mk
  GROUP BY mk.movie_id
),
aka_agg AS (
  SELECT 
    ci.movie_id,
    COUNT(DISTINCT an.id) AS aka_name_count
  FROM cast_info ci
  JOIN name n ON ci.person_id = n.id
  JOIN aka_name an ON an.person_id = n.id
  GROUP BY ci.movie_id
)
SELECT 
  t.title,
  t.production_year,
  ca.total_cast,
  ca.award_cast,
  ca.role_count,
  ka.keyword_count,
  aa.aka_name_count,
  (ca.total_cast + ca.award_cast + ca.role_count + ka.keyword_count + COALESCE(aa.aka_name_count, 0)) AS total_metric
FROM title t
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
LEFT JOIN aka_agg aa ON aa.movie_id = t.id
WHERE t.kind_id = 1
ORDER BY total_metric DESC
LIMIT 10
