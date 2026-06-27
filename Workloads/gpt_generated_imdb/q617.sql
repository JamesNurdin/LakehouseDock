WITH company_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        cn.imdb_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        COUNT(*) AS total_company_entries,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_type_count,
        AVG(LENGTH(mc.note)) FILTER (WHERE mc.note IS NOT NULL) AS avg_note_length
    FROM company_name cn
    JOIN movie_companies mc
        ON mc.company_id = cn.id
    GROUP BY
        cn.id,
        cn.name,
        cn.country_code,
        cn.imdb_id
)
SELECT
    company_id,
    company_name,
    country_code,
    imdb_id,
    movie_count,
    total_company_entries,
    distinct_company_type_count,
    avg_note_length,
    RANK() OVER (PARTITION BY country_code ORDER BY movie_count DESC) AS rank_within_country
FROM company_stats
WHERE movie_count >= 5
ORDER BY country_code, rank_within_country
LIMIT 200
