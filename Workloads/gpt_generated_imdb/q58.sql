WITH movie_cast AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keyword_filtered AS (
    SELECT mk.movie_id
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE lower(k.keyword) = 'love'
    GROUP BY mk.movie_id
),
movie_company AS (
    SELECT DISTINCT mc.movie_id,
                    ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT t.production_year,
       kt.kind AS title_kind,
       mc.company_type_kind,
       COUNT(DISTINCT t.id) AS movie_count,
       AVG(COALESCE(mca.cast_cnt, 0)) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword_filtered mkf ON t.id = mkf.movie_id
LEFT JOIN movie_cast mca ON t.id = mca.movie_id
JOIN movie_company mc ON t.id = mc.movie_id
WHERE t.production_year BETWEEN 1990 AND 2020
GROUP BY t.production_year, kt.kind, mc.company_type_kind
ORDER BY t.production_year DESC, movie_count DESC
LIMIT 50
