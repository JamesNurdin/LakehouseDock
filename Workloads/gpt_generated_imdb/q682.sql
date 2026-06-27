WITH per_movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.production_year, kt.kind
),
per_year_kind_stats AS (
    SELECT
        pmc.production_year,
        pmc.kind,
        COUNT(*) AS num_movies,
        AVG(pmc.cast_count) AS avg_cast_per_movie
    FROM per_movie_cast pmc
    GROUP BY pmc.production_year, pmc.kind
),
keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        k.keyword,
        COUNT(*) AS kw_occurrences
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, kt.kind, k.keyword
),
keyword_agg AS (
    SELECT
        production_year,
        kind,
        COUNT(DISTINCT keyword) AS distinct_keywords,
        element_at(ARRAY_AGG(keyword ORDER BY kw_occurrences DESC), 1) AS most_frequent_keyword
    FROM keyword_counts
    GROUP BY production_year, kind
)
SELECT
    pys.production_year,
    pys.kind,
    pys.num_movies,
    ROUND(pys.avg_cast_per_movie, 2) AS avg_cast_per_movie,
    ka.distinct_keywords,
    ka.most_frequent_keyword
FROM per_year_kind_stats pys
LEFT JOIN keyword_agg ka
    ON pys.production_year = ka.production_year
    AND pys.kind = ka.kind
ORDER BY pys.production_year DESC, pys.kind
