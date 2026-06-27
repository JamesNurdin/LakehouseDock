/*
  Analytical query: Top 20 movies (produced from 2000 onward) with the largest distinct cast size.
  For each movie we show:
    • Title, production year, kind
    • Number of distinct cast members (overall, male, female)
    • Number of distinct characters played
    • Number of distinct production companies and distinct company types
    • Number of distinct keywords
    • Percentile rank of the movie by cast size (1‑100)
  The query follows all join rules, uses only the listed tables/columns, and avoids SELECT *.
*/
WITH cast_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast,
        COUNT(DISTINCT ci.person_role_id) AS distinct_characters,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS distinct_male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS distinct_female_cast
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN name n ON ci.person_id = n.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
company_stats AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        COUNT(DISTINCT ct.kind) AS distinct_company_kinds
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY t.id
),
keyword_stats AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT 
    cs.title,
    cs.production_year,
    cs.kind,
    cs.distinct_cast,
    cs.distinct_male_cast,
    cs.distinct_female_cast,
    cs.distinct_characters,
    COALESCE(comp.distinct_companies, 0) AS distinct_companies,
    COALESCE(comp.distinct_company_kinds, 0) AS distinct_company_kinds,
    COALESCE(kw.distinct_keywords, 0) AS distinct_keywords,
    NTILE(100) OVER (ORDER BY cs.distinct_cast) AS cast_percentile
FROM cast_stats cs
LEFT JOIN company_stats comp ON cs.movie_id = comp.movie_id
LEFT JOIN keyword_stats kw ON cs.movie_id = kw.movie_id
WHERE cs.kind = 'movie'
  AND cs.production_year >= 2000
ORDER BY cs.distinct_cast DESC
LIMIT 20
