WITH actor_stats AS (
    SELECT 
        ci.person_id,
        name.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(title.production_year) AS avg_production_year,
        COUNT(DISTINCT cn.id) AS distinct_companies
    FROM cast_info ci
    JOIN name ON ci.person_id = name.id
    JOIN title ON ci.movie_id = title.id
    LEFT JOIN movie_companies mc ON mc.movie_id = title.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY ci.person_id, name.name
),
actor_kind_counts AS (
    SELECT 
        ci.person_id,
        name.name AS actor_name,
        kt.kind AS kind,
        COUNT(DISTINCT ci.movie_id) AS kind_movie_count
    FROM cast_info ci
    JOIN name ON ci.person_id = name.id
    JOIN title ON ci.movie_id = title.id
    JOIN kind_type kt ON title.kind_id = kt.id
    GROUP BY ci.person_id, name.name, kt.kind
),
actor_top_kind AS (
    SELECT person_id, kind, kind_movie_count
    FROM (
        SELECT 
            person_id,
            kind,
            kind_movie_count,
            ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY kind_movie_count DESC) AS rn
        FROM actor_kind_counts
    ) t
    WHERE rn = 1
)
SELECT 
    a.actor_name,
    a.total_movies,
    a.avg_production_year,
    a.distinct_companies,
    k.kind AS most_frequent_kind,
    k.kind_movie_count AS movies_in_kind
FROM actor_stats a
JOIN actor_top_kind k ON a.person_id = k.person_id
ORDER BY a.total_movies DESC
LIMIT 10
