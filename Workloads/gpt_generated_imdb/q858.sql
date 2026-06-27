/*
   Analytical query: for each movie kind (e.g., "movie", "short", "TV series") and production year (>= 2000)
   report the number of movies, average number of cast members per movie, the count of distinct keywords
   attached to those movies, and the count of distinct production companies involved.
   All joins follow the allowed rules and the query uses only the selected tables.
*/
WITH movies_counts AS (
    SELECT
        t.kind_id,
        kt.kind,
        t.production_year,
        COUNT(DISTINCT t.id) AS movies_cnt
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.kind_id, kt.kind, t.production_year
),
cast_counts AS (
    SELECT
        t.kind_id,
        t.production_year,
        COUNT(ci.person_id) AS cast_members
    FROM title t
    JOIN cast_info ci
        ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.kind_id, t.production_year
),
keyword_counts AS (
    SELECT
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS distinct_keywords_cnt
    FROM title t
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword k
        ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.kind_id, t.production_year
),
company_counts AS (
    SELECT
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS distinct_companies_cnt
    FROM title t
    JOIN movie_companies mc
        ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.kind_id, t.production_year
)
SELECT
    mc.kind,
    mc.production_year,
    mc.movies_cnt,
    CAST(COALESCE(cc.cast_members, 0) AS double) / NULLIF(mc.movies_cnt, 0) AS avg_cast_per_movie,
    COALESCE(kc.distinct_keywords_cnt, 0) AS distinct_keywords_cnt,
    COALESCE(compc.distinct_companies_cnt, 0) AS distinct_companies_cnt
FROM movies_counts mc
LEFT JOIN cast_counts cc
    ON cc.kind_id = mc.kind_id
   AND cc.production_year = mc.production_year
LEFT JOIN keyword_counts kc
    ON kc.kind_id = mc.kind_id
   AND kc.production_year = mc.production_year
LEFT JOIN company_counts compc
    ON compc.kind_id = mc.kind_id
   AND compc.production_year = mc.production_year
WHERE mc.production_year >= 2000
ORDER BY mc.production_year DESC, mc.kind
