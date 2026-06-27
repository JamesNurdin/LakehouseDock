WITH movie_ratings AS (
    SELECT mi.movie_id,
           MAX(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
filtered_movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
),
movie_stats AS (
    SELECT fm.movie_id,
           fm.title,
           fm.production_year,
           mr.rating,
           COALESCE(mcc.cast_count, 0) AS cast_count,
           COALESCE(mcp.company_count, 0) AS company_count
    FROM filtered_movies fm
    LEFT JOIN movie_ratings mr ON mr.movie_id = fm.movie_id
    LEFT JOIN movie_cast_counts mcc ON mcc.movie_id = fm.movie_id
    LEFT JOIN movie_company_counts mcp ON mcp.movie_id = fm.movie_id
),
keyword_movie AS (
    SELECT mk.movie_id,
           k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
)
SELECT km.keyword,
       COUNT(DISTINCT ms.movie_id) AS movie_count,
       ROUND(AVG(ms.rating), 2) AS avg_rating,
       ROUND(AVG(ms.cast_count), 2) AS avg_cast_count,
       ROUND(AVG(ms.company_count), 2) AS avg_company_count
FROM keyword_movie km
JOIN movie_stats ms ON km.movie_id = ms.movie_id
GROUP BY km.keyword
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
