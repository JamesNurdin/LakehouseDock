WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        MAX(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS double) END) AS rating,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN n.id END) AS male_cast_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN n.id END) AS female_cast_count,
        COUNT(DISTINCT mc.company_id) AS total_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production company' THEN mc.company_id END) AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    rating,
    cast_count,
    male_cast_count,
    female_cast_count,
    total_company_count,
    production_company_count,
    keyword_count
FROM movie_stats
WHERE rating IS NOT NULL
ORDER BY rating DESC
LIMIT 100
