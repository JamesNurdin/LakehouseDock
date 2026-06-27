WITH movie_stats AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(cast_counts.cast_cnt) AS avg_cast_per_movie,
        AVG(kw_counts.kw_cnt) AS avg_keywords_per_movie,
        AVG(comp_counts.comp_cnt) AS avg_companies_per_movie
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN (
        SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ) cast_counts ON cast_counts.movie_id = t.id
    LEFT JOIN (
        SELECT mk.movie_id, COUNT(DISTINCT mk.keyword_id) AS kw_cnt
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ) kw_counts ON kw_counts.movie_id = t.id
    LEFT JOIN (
        SELECT mc.movie_id, COUNT(DISTINCT mc.company_id) AS comp_cnt
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ) comp_counts ON comp_counts.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),

top_keyword AS (
    SELECT
        production_year,
        kind,
        keyword,
        kw_occurrences
    FROM (
        SELECT
            t.production_year,
            kt.kind,
            k.keyword,
            COUNT(*) AS kw_occurrences,
            ROW_NUMBER() OVER (PARTITION BY t.production_year, kt.kind ORDER BY COUNT(*) DESC) AS rn
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN movie_keyword mk ON mk.movie_id = t.id
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE t.production_year IS NOT NULL
        GROUP BY t.production_year, kt.kind, k.keyword
    ) sub
    WHERE rn = 1
)
SELECT
    ms.production_year,
    ms.kind,
    ms.movie_count,
    ROUND(ms.avg_cast_per_movie, 2) AS avg_cast_per_movie,
    ROUND(ms.avg_keywords_per_movie, 2) AS avg_keywords_per_movie,
    ROUND(ms.avg_companies_per_movie, 2) AS avg_companies_per_movie,
    tk.keyword AS top_keyword,
    tk.kw_occurrences AS top_keyword_occurrences
FROM movie_stats ms
LEFT JOIN top_keyword tk
    ON ms.production_year = tk.production_year
   AND ms.kind = tk.kind
ORDER BY ms.production_year DESC, ms.kind
