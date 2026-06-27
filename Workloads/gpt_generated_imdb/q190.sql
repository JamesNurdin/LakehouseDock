WITH actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
budget_gross AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN mi.note END) AS budget,
        MAX(CASE WHEN it.info = 'gross' THEN mi.note END) AS gross
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
production_companies AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS production_company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_titles AS (
    SELECT
        t.id,
        t.title,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
)
SELECT
    mt.title,
    mt.production_year,
    ac.distinct_actor_count,
    bg.budget,
    bg.gross,
    pc.production_company_names
FROM movie_titles mt
LEFT JOIN actor_counts ac ON mt.id = ac.movie_id
LEFT JOIN budget_gross bg ON mt.id = bg.movie_id
LEFT JOIN production_companies pc ON mt.id = pc.movie_id
ORDER BY bg.gross DESC NULLS LAST
LIMIT 10
