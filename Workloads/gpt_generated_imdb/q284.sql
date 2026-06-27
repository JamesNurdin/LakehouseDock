/*
  Analytical query: for each movie released from the year 2000 onward (kind = 'movie'),
  compute the number of distinct cast members, production companies, keywords, and generic
  movie‑info entries. Also count how many of those info entries are of type 'budget'.
  Finally, calculate the percentile rank of the cast‑member count within each production year.
*/
WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title AS title,
        t.production_year AS production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.id) AS info_count,
        COUNT(DISTINCT CASE WHEN it.info = 'budget' THEN mi.id END) AS budget_info_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    title,
    production_year,
    kind,
    cast_count,
    company_count,
    keyword_count,
    info_count,
    budget_info_count,
    PERCENT_RANK() OVER (PARTITION BY production_year ORDER BY cast_count) AS cast_count_percentile
FROM movie_metrics
ORDER BY cast_count DESC
LIMIT 50
