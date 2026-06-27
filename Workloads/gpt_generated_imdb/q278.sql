-- Movies per kind with production year, cast size and a specific keyword
WITH movies_by_kind AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movies_with_keyword AS (
    SELECT DISTINCT
        mk.movie_id AS title_id
    FROM movie_keyword mk
    JOIN keyword k
        ON mk.keyword_id = k.id
    WHERE k.keyword = 'love'
)
SELECT
    mbk.kind,
    COUNT(DISTINCT mbk.title_id) AS movie_count,
    AVG(mbk.production_year) AS avg_production_year,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    COUNT(DISTINCT mwk.title_id) AS love_movie_count
FROM movies_by_kind mbk
LEFT JOIN cast_counts cc
    ON mbk.title_id = cc.title_id
LEFT JOIN movies_with_keyword mwk
    ON mbk.title_id = mwk.title_id
GROUP BY mbk.kind
ORDER BY movie_count DESC
