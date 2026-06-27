WITH movie_metrics AS (
    SELECT
        mc.company_id,
        t.kind_id,
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY mc.company_id, t.kind_id, t.id
),
company_kind_stats AS (
    SELECT
        cn.name AS company_name,
        kt.kind AS kind,
        COUNT(*) AS movie_count,
        AVG(cast_count) AS avg_cast_per_movie,
        AVG(keyword_count) AS avg_keywords_per_movie
    FROM movie_metrics mm
    JOIN company_name cn ON mm.company_id = cn.id
    JOIN kind_type kt ON mm.kind_id = kt.id
    GROUP BY cn.name, kt.kind
)
SELECT
    company_name,
    kind,
    movie_count,
    avg_cast_per_movie,
    avg_keywords_per_movie
FROM company_kind_stats
ORDER BY movie_count DESC
LIMIT 10
