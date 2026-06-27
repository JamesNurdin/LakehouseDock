WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT k.id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(ci.nr_order) AS total_cast_order,
        AVG(ci.nr_order) AS avg_cast_order
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT *
FROM movie_details
ORDER BY cast_count DESC
LIMIT 20
