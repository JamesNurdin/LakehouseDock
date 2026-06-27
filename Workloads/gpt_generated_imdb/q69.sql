WITH movies AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
actors_per_kind AS (
    SELECT
        kt.kind AS movie_kind,
        COUNT(DISTINCT ci.person_id) AS distinct_actors
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind
),
production_companies_per_kind AS (
    SELECT
        kt.kind AS movie_kind,
        COUNT(DISTINCT cn.name) AS distinct_production_companies
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE t.production_year >= 2000
      AND ct.kind = 'production'
    GROUP BY kt.kind
),
keyword_counts AS (
    SELECT
        movie_id,
        COUNT(*) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
keyword_stats_per_kind AS (
    SELECT
        m.movie_kind,
        AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie
    FROM movies m
    LEFT JOIN keyword_counts kc ON m.id = kc.movie_id
    GROUP BY m.movie_kind
),
movie_stats_per_kind AS (
    SELECT
        kt.kind AS movie_kind,
        COUNT(*) AS total_movies,
        AVG(t.production_year) AS avg_production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind
)
SELECT
    ms.movie_kind,
    ms.total_movies,
    ms.avg_production_year,
    COALESCE(ac.distinct_actors, 0) AS distinct_actors,
    COALESCE(pc.distinct_production_companies, 0) AS distinct_production_companies,
    ks.avg_keywords_per_movie
FROM movie_stats_per_kind ms
LEFT JOIN actors_per_kind ac ON ms.movie_kind = ac.movie_kind
LEFT JOIN production_companies_per_kind pc ON ms.movie_kind = pc.movie_kind
LEFT JOIN keyword_stats_per_kind ks ON ms.movie_kind = ks.movie_kind
ORDER BY ms.total_movies DESC
LIMIT 10
