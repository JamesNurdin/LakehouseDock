WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_companies_info AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS production_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN cn.id END) AS distribution_company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    am.actor_id,
    am.actor_name,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    AVG(am.production_year) AS avg_release_year,
    COALESCE(SUM(mk.keyword_count), 0) AS total_keywords,
    COALESCE(CAST(SUM(mk.keyword_count) AS double) / NULLIF(COUNT(DISTINCT am.movie_id), 0), 0) AS avg_keywords_per_movie,
    COALESCE(SUM(mci.company_count), 0) AS total_companies,
    COALESCE(CAST(SUM(mci.company_count) AS double) / NULLIF(COUNT(DISTINCT am.movie_id), 0), 0) AS avg_companies_per_movie,
    COALESCE(SUM(mci.production_company_count), 0) AS total_production_companies,
    COALESCE(SUM(mci.distribution_company_count), 0) AS total_distribution_companies
FROM actor_movies am
LEFT JOIN movie_keywords mk ON am.movie_id = mk.movie_id
LEFT JOIN movie_companies_info mci ON am.movie_id = mci.movie_id
GROUP BY am.actor_id, am.actor_name
ORDER BY movie_count DESC, total_keywords DESC
LIMIT 10
