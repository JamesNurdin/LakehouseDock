WITH movie_cast_counts AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
movie_company_counts AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
movie_keyword_list AS (
    SELECT t.id AS movie_id,
           k.keyword
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
),
movie_base AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    WHERE t.production_year >= 2000
),
keyword_freq AS (
    SELECT mb.kind,
           mb.production_year,
           mk.keyword,
           COUNT(DISTINCT mb.movie_id) AS keyword_count,
           ROW_NUMBER() OVER (PARTITION BY mb.kind, mb.production_year ORDER BY COUNT(DISTINCT mb.movie_id) DESC) AS rn
    FROM movie_base mb
    JOIN movie_keyword_list mk ON mk.movie_id = mb.movie_id
    GROUP BY mb.kind, mb.production_year, mk.keyword
)
SELECT mb.kind,
       mb.production_year,
       COUNT(DISTINCT mb.movie_id) AS total_movies,
       AVG(COALESCE(mc.cast_count, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(mco.company_count, 0)) AS avg_companies_per_movie,
       kw.keyword AS most_common_keyword,
       kw.keyword_count AS keyword_movie_count
FROM movie_base mb
LEFT JOIN movie_cast_counts mc ON mc.movie_id = mb.movie_id
LEFT JOIN movie_company_counts mco ON mco.movie_id = mb.movie_id
LEFT JOIN (
    SELECT kind,
           production_year,
           keyword,
           keyword_count
    FROM keyword_freq
    WHERE rn = 1
) kw ON kw.kind = mb.kind AND kw.production_year = mb.production_year
GROUP BY mb.kind, mb.production_year, kw.keyword, kw.keyword_count
ORDER BY mb.kind, mb.production_year
