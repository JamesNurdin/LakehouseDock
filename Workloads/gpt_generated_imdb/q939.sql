WITH title_stats AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(mi.id) AS info_cnt,
        COUNT(mix.id) AS info_idx_cnt
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN movie_info_idx mix
        ON mix.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
year_kind_stats AS (
    SELECT
        kind,
        CAST(production_year AS integer) AS prod_year,
        COUNT(*) AS num_titles,
        AVG(company_cnt) AS avg_companies,
        AVG(info_cnt) AS avg_info,
        AVG(info_idx_cnt) AS avg_info_idx
    FROM title_stats
    WHERE production_year IS NOT NULL
    GROUP BY kind, CAST(production_year AS integer)
),
ranked_stats AS (
    SELECT
        kind,
        prod_year,
        num_titles,
        avg_companies,
        avg_info,
        avg_info_idx,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY avg_companies DESC) AS rn
    FROM year_kind_stats
)
SELECT
    kind,
    prod_year,
    num_titles,
    avg_companies,
    avg_info,
    avg_info_idx
FROM ranked_stats
WHERE rn <= 5
ORDER BY kind, prod_year
