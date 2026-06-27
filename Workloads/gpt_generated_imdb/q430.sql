WITH cast_counts AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year > 2000
    GROUP BY ci.movie_id
),
char_counts AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT cn.id) AS char_count
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year > 2000
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id AS movie_id,
           COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year > 2000
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id AS movie_id,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year > 2000
    GROUP BY mk.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind_name,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(chc.char_count, 0) AS char_count,
       COALESCE(comc.company_count, 0) AS company_count,
       COALESCE(kwc.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc   ON t.id = cc.movie_id
LEFT JOIN char_counts chc  ON t.id = chc.movie_id
LEFT JOIN company_counts comc ON t.id = comc.movie_id
LEFT JOIN keyword_counts kwc ON t.id = kwc.movie_id
WHERE t.production_year > 2000
ORDER BY cast_count DESC
LIMIT 10
