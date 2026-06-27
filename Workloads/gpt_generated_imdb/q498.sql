WITH movie_cast_counts AS (
    SELECT 
        cn.id AS company_id,
        cn.name AS company_name,
        t.id AS movie_id,
        COUNT(DISTINCT n.id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON n.id = ci.person_id
    WHERE t.production_year = 2020
      AND kt.kind = 'movie'
    GROUP BY cn.id, cn.name, t.id
),
movie_keyword_counts AS (
    SELECT 
        cn.id AS company_id,
        cn.name AS company_name,
        kw.keyword,
        COUNT(DISTINCT t.id) AS movie_keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON kw.id = mk.keyword_id
    WHERE t.production_year = 2020
      AND kt.kind = 'movie'
    GROUP BY cn.id, cn.name, kw.keyword
),
top_keyword_per_company AS (
    SELECT 
        company_id,
        company_name,
        keyword,
        movie_keyword_count,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY movie_keyword_count DESC) AS rn
    FROM movie_keyword_counts
)
SELECT 
    mc.company_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    tk.keyword AS top_keyword,
    tk.movie_keyword_count AS top_keyword_movie_count
FROM movie_cast_counts mc
JOIN top_keyword_per_company tk 
    ON tk.company_id = mc.company_id 
   AND tk.rn = 1
GROUP BY mc.company_name, tk.keyword, tk.movie_keyword_count
ORDER BY total_movies DESC
LIMIT 10
