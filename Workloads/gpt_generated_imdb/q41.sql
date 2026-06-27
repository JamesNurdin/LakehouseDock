WITH movies AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        k.keyword AS keyword
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword k
        ON mk.keyword_id = k.id
    WHERE t.production_year >= 2010
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_cnt
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    m.kind,
    m.keyword,
    COUNT(DISTINCT m.movie_id) AS movie_cnt,
    AVG(cc.company_cnt) AS avg_companies_per_movie,
    AVG(ic.info_cnt) AS avg_info_entries_per_movie
FROM movies m
LEFT JOIN company_counts cc
    ON cc.movie_id = m.movie_id
LEFT JOIN info_counts ic
    ON ic.movie_id = m.movie_id
GROUP BY
    m.kind,
    m.keyword
ORDER BY
    movie_cnt DESC,
    avg_companies_per_movie DESC
LIMIT 20
