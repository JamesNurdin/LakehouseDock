WITH movie_info AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    cn.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mi.movie_id) AS total_movies,
    AVG(mi.keyword_cnt) AS avg_keywords_per_movie
FROM movie_companies mc
JOIN movie_info mi ON mc.movie_id = mi.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type ct ON mc.company_type_id = ct.id
GROUP BY cn.name, ct.kind
ORDER BY total_movies DESC
LIMIT 10
