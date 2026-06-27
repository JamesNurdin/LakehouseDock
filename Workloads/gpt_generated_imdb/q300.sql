WITH movie_stats AS (
    SELECT
        mc.company_id,
        COUNT(DISTINCT t.id) AS movies_produced,
        AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE ct.kind = 'production'
      AND it.info = 'rating'
      AND kt.kind = 'movie'
    GROUP BY mc.company_id
),
cast_stats AS (
    SELECT
        mc.company_id,
        COUNT(DISTINCT ci.person_id) AS total_distinct_cast
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE ct.kind = 'production'
      AND kt.kind = 'movie'
    GROUP BY mc.company_id
),
keyword_freq AS (
    SELECT
        mc.company_id,
        k.keyword,
        COUNT(*) AS freq
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE ct.kind = 'production'
      AND kt.kind = 'movie'
    GROUP BY mc.company_id, k.keyword
),
most_common_keyword AS (
    SELECT
        company_id,
        keyword
    FROM (
        SELECT
            company_id,
            keyword,
            ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY freq DESC) AS rn
        FROM keyword_freq
    )
    WHERE rn = 1
)
SELECT
    cn.name AS company_name,
    ms.movies_produced,
    ms.avg_rating,
    cs.total_distinct_cast,
    mk.keyword AS most_common_keyword
FROM company_name cn
JOIN movie_stats ms ON cn.id = ms.company_id
LEFT JOIN cast_stats cs ON cn.id = cs.company_id
LEFT JOIN most_common_keyword mk ON cn.id = mk.company_id
WHERE ms.movies_produced >= 5
ORDER BY ms.avg_rating DESC
LIMIT 20
