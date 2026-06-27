WITH actor_year_stats AS (
    SELECT
        ci.person_id,
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(r.note) AS avg_rating,
        COUNT(DISTINCT cn.id) AS distinct_company_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info_idx r ON r.movie_id = t.id
    LEFT JOIN info_type it ON r.info_type_id = it.id AND it.info = 'rating'
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE kt.kind = 'movie' AND t.production_year IS NOT NULL
    GROUP BY ci.person_id, t.production_year
),
ranked_actors AS (
    SELECT
        person_id,
        production_year,
        movie_count,
        avg_rating,
        distinct_company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM actor_year_stats
)
SELECT
    person_id,
    production_year,
    movie_count,
    avg_rating,
    distinct_company_count
FROM ranked_actors
WHERE rn <= 5
ORDER BY production_year DESC, movie_count DESC
