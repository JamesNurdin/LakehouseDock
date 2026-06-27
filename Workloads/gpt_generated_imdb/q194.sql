WITH movies AS (
    SELECT t.id AS movie_id,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
),
cast_per_movie AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
distinct_cast_members_per_year_kind AS (
    SELECT m.production_year,
           m.kind,
           COUNT(DISTINCT ci.person_id) AS distinct_cast_members
    FROM movies m
    JOIN cast_info ci ON ci.movie_id = m.movie_id
    GROUP BY m.production_year, m.kind
),
total_movies_per_year_kind AS (
    SELECT m.production_year,
           m.kind,
           COUNT(DISTINCT m.movie_id) AS total_movies
    FROM movies m
    GROUP BY m.production_year, m.kind
),
avg_cast_per_movie_per_year_kind AS (
    SELECT m.production_year,
           m.kind,
           AVG(cp.cast_count * 1.0) AS avg_cast_per_movie
    FROM movies m
    LEFT JOIN cast_per_movie cp ON cp.movie_id = m.movie_id
    GROUP BY m.production_year, m.kind
),
movie_companies_agg AS (
    SELECT mc.movie_id,
           cn.name AS company_name
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
),
movie_count_per_company AS (
    SELECT m.production_year,
           m.kind,
           ca.company_name,
           COUNT(DISTINCT m.movie_id) AS movie_count
    FROM movies m
    JOIN movie_companies_agg ca ON ca.movie_id = m.movie_id
    GROUP BY m.production_year, m.kind, ca.company_name
),
top_company_per_year_kind AS (
    SELECT mc.production_year,
           mc.kind,
           mc.company_name,
           mc.movie_count,
           ROW_NUMBER() OVER (PARTITION BY mc.production_year, mc.kind ORDER BY mc.movie_count DESC) AS rn
    FROM movie_count_per_company mc
)
SELECT
    tm.production_year,
    tm.kind,
    tm.total_movies,
    dcm.distinct_cast_members,
    ac.avg_cast_per_movie,
    tc.company_name AS top_company_name,
    tc.movie_count AS top_company_movie_count
FROM total_movies_per_year_kind tm
JOIN distinct_cast_members_per_year_kind dcm
    ON tm.production_year = dcm.production_year AND tm.kind = dcm.kind
JOIN avg_cast_per_movie_per_year_kind ac
    ON tm.production_year = ac.production_year AND tm.kind = ac.kind
JOIN top_company_per_year_kind tc
    ON tm.production_year = tc.production_year AND tm.kind = tc.kind
WHERE tc.rn = 1
ORDER BY tm.production_year DESC, tm.kind
