WITH keyword_movie_stats AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        SUM(cast_counts.cast_cnt) AS total_cast_members
    FROM keyword k
    JOIN movie_keyword mk ON mk.keyword_id = k.id
    JOIN title t ON mk.movie_id = t.id
    LEFT JOIN (
        SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ) cast_counts ON cast_counts.movie_id = t.id
    WHERE t.production_year >= 2000
      AND t.kind_id = 1
    GROUP BY k.id, k.keyword
)
SELECT
    keyword_id,
    keyword,
    movie_count,
    avg_production_year,
    total_cast_members
FROM keyword_movie_stats
ORDER BY movie_count DESC, total_cast_members DESC
LIMIT 20
