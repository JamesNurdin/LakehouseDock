WITH runtime_info AS (
    SELECT mi.movie_id, mi.note
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
budget_info AS (
    SELECT mi.movie_id, mi.note
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
info_counts AS (
    SELECT movie_id, COUNT(*) AS info_cnt
    FROM movie_info
    GROUP BY movie_id
),
movie_metrics AS (
    SELECT
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(ri.note) AS runtime_minutes,
        MAX(bi.note) AS budget_usd,
        COALESCE(ic.info_cnt, 0) AS info_entry_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN runtime_info ri ON ri.movie_id = t.id
    LEFT JOIN budget_info bi ON bi.movie_id = t.id
    LEFT JOIN info_counts ic ON ic.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind, COALESCE(ic.info_cnt, 0)
)
SELECT
    title,
    production_year,
    kind,
    company_count,
    keyword_count,
    runtime_minutes,
    budget_usd,
    info_entry_count,
    ROW_NUMBER() OVER (ORDER BY company_count DESC) AS rank
FROM movie_metrics
ORDER BY rank
LIMIT 100
