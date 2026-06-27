WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
movie_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        k.keyword AS keyword,
        COUNT(*) AS kw_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, k.keyword
),
top_keyword_per_movie AS (
    SELECT
        movie_id,
        (ARRAY_AGG(keyword ORDER BY kw_count DESC))[1] AS top_keyword
    FROM movie_keyword_counts
    GROUP BY movie_id
)
SELECT
    kt.kind AS kind,
    CAST(t.production_year AS INTEGER) AS production_year,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(cm.company_count) AS avg_companies_per_movie,
    (ARRAY_AGG(tk.top_keyword ORDER BY tk.top_keyword))[1] AS example_top_keyword
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
LEFT JOIN movie_company_counts cm ON cm.movie_id = t.id
LEFT JOIN top_keyword_per_movie tk ON tk.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY total_movies DESC
LIMIT 20
