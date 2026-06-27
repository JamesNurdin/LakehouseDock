WITH actor_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
),
actor_summary AS (
    SELECT
        person_id,
        person_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        AVG(production_year) AS avg_production_year
    FROM actor_movies
    GROUP BY person_id, person_name
),
actor_keyword_counts AS (
    SELECT
        am.person_id,
        k.keyword,
        COUNT(DISTINCT am.movie_id) AS keyword_movie_count
    FROM actor_movies am
    JOIN movie_keyword mk ON am.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY am.person_id, k.keyword
),
actor_top_keyword AS (
    SELECT
        person_id,
        keyword,
        keyword_movie_count,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY keyword_movie_count DESC, keyword) AS rn
    FROM actor_keyword_counts
),
actor_top_keyword_filtered AS (
    SELECT
        person_id,
        keyword AS top_keyword,
        keyword_movie_count AS top_keyword_movie_count
    FROM actor_top_keyword
    WHERE rn = 1
)
SELECT
    asum.person_name,
    asum.movie_count,
    asum.avg_production_year,
    atk.top_keyword,
    atk.top_keyword_movie_count
FROM actor_summary asum
JOIN actor_top_keyword_filtered atk ON asum.person_id = atk.person_id
ORDER BY asum.movie_count DESC, asum.person_name
LIMIT 10
