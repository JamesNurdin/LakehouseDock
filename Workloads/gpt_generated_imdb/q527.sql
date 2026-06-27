WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
movie_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
)
SELECT
    k.keyword,
    kt.kind,
    COUNT(DISTINCT t.id) AS num_movies,
    AVG(mc.num_companies) AS avg_num_companies,
    AVG(cc.num_cast) AS avg_num_cast
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
LEFT JOIN movie_company_counts mc ON mc.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY k.keyword, kt.kind
ORDER BY num_movies DESC
LIMIT 100
