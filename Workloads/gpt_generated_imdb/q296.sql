/*
  Top 20 actors by number of feature‑film appearances, with additional activity metrics.
  The query:
    • Joins cast_info → name → title (filtered to kind = 'movie')
    • Links to char_name for distinct characters played
    • Links to movie_companies → company_type to count distinct companies and company types per actor
    • Aggregates per actor and ranks them by movie count.
*/
WITH actor_movie_company AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name,
        mc.company_id,
        ct.kind AS company_type_kind,
        kt.kind AS movie_kind
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE kt.kind = 'movie'
),
actor_aggregates AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        COUNT(DISTINCT character_name) AS distinct_character_count,
        MIN(production_year) AS earliest_production_year,
        COUNT(DISTINCT company_id) AS distinct_company_count,
        COUNT(DISTINCT company_type_kind) AS distinct_company_type_count
    FROM actor_movie_company
    GROUP BY actor_id, actor_name
)
SELECT
    actor_id,
    actor_name,
    movie_count,
    distinct_character_count,
    earliest_production_year,
    distinct_company_count,
    distinct_company_type_count,
    RANK() OVER (ORDER BY movie_count DESC) AS actor_rank_by_movies
FROM actor_aggregates
ORDER BY movie_count DESC
LIMIT 20
