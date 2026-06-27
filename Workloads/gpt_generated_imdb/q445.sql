WITH movie_base AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS genre
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_type_per_genre AS (
    SELECT
        mb.genre,
        ct.kind AS company_type,
        COUNT(*) AS cnt
    FROM movie_base mb
    JOIN movie_companies mc ON mc.movie_id = mb.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mb.genre, ct.kind
),
top_company_type AS (
    SELECT
        ctpg.genre,
        ctpg.company_type,
        ctpg.cnt
    FROM (
        SELECT
            ctpg.genre,
            ctpg.company_type,
            ctpg.cnt,
            ROW_NUMBER() OVER (PARTITION BY ctpg.genre ORDER BY ctpg.cnt DESC) AS rn
        FROM company_type_per_genre ctpg
    ) ctpg
    WHERE ctpg.rn = 1
)
SELECT
    mb.genre,
    COUNT(DISTINCT mb.movie_id) AS total_movies,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    tct.company_type AS top_company_type,
    tct.cnt AS top_company_type_movie_count
FROM movie_base mb
LEFT JOIN cast_counts cc ON cc.movie_id = mb.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = mb.movie_id
LEFT JOIN top_company_type tct ON tct.genre = mb.genre
GROUP BY mb.genre, tct.company_type, tct.cnt
ORDER BY total_movies DESC
LIMIT 10
