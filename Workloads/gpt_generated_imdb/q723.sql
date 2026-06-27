WITH cast_stats AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast_count,
           COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast_count,
           COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY t.id, t.title, t.production_year
),
company_stats AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    GROUP BY t.id
),
keyword_stats AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    GROUP BY t.id
),
info_stats AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    JOIN title t ON mi.movie_id = t.id
    GROUP BY t.id
)
SELECT cs.title,
       cs.production_year,
       cs.cast_count,
       cs.male_cast_count,
       cs.female_cast_count,
       cs.character_count,
       co.company_count,
       kw.keyword_count,
       inf.info_type_count
FROM cast_stats cs
LEFT JOIN company_stats co ON cs.movie_id = co.movie_id
LEFT JOIN keyword_stats kw ON cs.movie_id = kw.movie_id
LEFT JOIN info_stats inf ON cs.movie_id = inf.movie_id
WHERE cs.production_year >= 2000
ORDER BY cs.cast_count DESC
LIMIT 10
