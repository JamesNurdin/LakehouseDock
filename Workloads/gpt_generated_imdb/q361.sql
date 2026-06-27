WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_kinds AS (
    SELECT t.kind_id,
           ct.kind AS kind_name,
           COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM title t
    JOIN kind_type ct ON t.kind_id = ct.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.kind_id, ct.kind
),
movie_stats AS (
    SELECT t.kind_id,
           ct.kind AS kind_name,
           COUNT(*) AS total_movies,
           AVG(t.production_year) AS avg_production_year,
           AVG(cc.cast_count) AS avg_cast_per_movie,
           AVG(kc.keyword_count) AS avg_keywords_per_movie
    FROM title t
    JOIN kind_type ct ON t.kind_id = ct.id
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    GROUP BY t.kind_id, ct.kind
)
SELECT ms.kind_name,
       ms.total_movies,
       ms.avg_production_year,
       ms.avg_cast_per_movie,
       ms.avg_keywords_per_movie,
       ck.distinct_company_count
FROM movie_stats ms
JOIN company_kinds ck ON ck.kind_id = ms.kind_id
ORDER BY ms.total_movies DESC
LIMIT 10
