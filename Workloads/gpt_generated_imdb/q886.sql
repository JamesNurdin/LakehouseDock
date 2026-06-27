WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        cn.imdb_id,
        cn.md5sum,
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_count,
        COUNT(*) AS total_company_entries,
        MIN(mc.note) AS example_note
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE cn.country_code = 'US'
      AND mc.note IS NOT NULL
    GROUP BY cn.id, cn.name, cn.country_code, cn.imdb_id, cn.md5sum, mc.company_type_id
),
ranked_companies AS (
    SELECT
        company_id,
        company_name,
        country_code,
        imdb_id,
        md5sum,
        company_type_id,
        distinct_movie_count,
        total_company_entries,
        example_note,
        ROW_NUMBER() OVER (ORDER BY distinct_movie_count DESC, total_company_entries DESC) AS rank
    FROM company_movie_stats
)
SELECT
    company_id,
    company_name,
    country_code,
    imdb_id,
    md5sum,
    company_type_id,
    distinct_movie_count,
    total_company_entries,
    example_note,
    rank
FROM ranked_companies
WHERE rank <= 10
ORDER BY rank
