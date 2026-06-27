WITH cast_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year
),
keyword_stats AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
company_stats AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
budget_stats AS (
    SELECT
        t.id AS movie_id,
        MAX(TRY_CAST(mi.info AS double)) AS budget
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY t.id
),
gross_stats AS (
    SELECT
        t.id AS movie_id,
        MAX(TRY_CAST(mi.info AS double)) AS gross
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'gross'
    GROUP BY t.id
)
SELECT
    cs.title,
    cs.production_year,
    cs.cast_count,
    ks.keyword_count,
    comps.company_count,
    bs.budget,
    gs.gross,
    (gs.gross - bs.budget) AS profit,
    (cs.cast_count + ks.keyword_count + comps.company_count) AS total_elements
FROM cast_stats cs
JOIN keyword_stats ks ON ks.movie_id = cs.movie_id
JOIN company_stats comps ON comps.movie_id = cs.movie_id
LEFT JOIN budget_stats bs ON bs.movie_id = cs.movie_id
LEFT JOIN gross_stats gs ON gs.movie_id = cs.movie_id
WHERE cs.production_year >= 2000
ORDER BY profit DESC NULLS LAST, total_elements DESC
LIMIT 10
