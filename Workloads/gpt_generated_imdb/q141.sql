WITH cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
aka_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ak.id) AS aka_name_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN aka_name ak ON ak.person_id = n.id
    GROUP BY ci.movie_id
),
kw_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
comp_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(*) AS num_movies,
    AVG(COALESCE(ca.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(aa.aka_name_count, 0)) AS avg_aka_names_per_movie,
    AVG(COALESCE(kw.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(cp.company_count, 0)) AS avg_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca   ON ca.movie_id   = t.id
LEFT JOIN aka_agg aa    ON aa.movie_id   = t.id
LEFT JOIN kw_agg kw     ON kw.movie_id   = t.id
LEFT JOIN comp_agg cp   ON cp.movie_id   = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
