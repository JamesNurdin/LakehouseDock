WITH movie_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(ci.id) AS total_cast_entries,
        COUNT(CASE WHEN n.gender = 'F' THEN 1 END) AS female_cast_entries
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN name n
        ON ci.person_id = n.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(mk.id) AS total_keyword_entries
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(DISTINCT mc.movie_id) AS num_movies,
    COALESCE(cc.total_cast_entries, 0) AS total_cast_entries,
    COALESCE(cc.female_cast_entries, 0) AS female_cast_entries,
    CASE
        WHEN COALESCE(cc.total_cast_entries, 0) = 0 THEN 0
        ELSE COALESCE(cc.female_cast_entries, 0) * 1.0 / cc.total_cast_entries
    END AS female_cast_proportion,
    COALESCE(kc.total_keyword_entries, 0) AS total_keyword_entries,
    COALESCE(kc.total_keyword_entries, 0) * 1.0 / NULLIF(COUNT(DISTINCT mc.movie_id), 0) AS avg_keywords_per_movie
FROM movie_counts mc
LEFT JOIN cast_counts cc
    ON mc.production_year = cc.production_year
   AND mc.kind = cc.kind
LEFT JOIN keyword_counts kc
    ON mc.production_year = kc.production_year
   AND mc.kind = kc.kind
GROUP BY
    mc.production_year,
    mc.kind,
    cc.total_cast_entries,
    cc.female_cast_entries,
    kc.total_keyword_entries
ORDER BY num_movies DESC
LIMIT 10
