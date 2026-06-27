WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT CASE WHEN it.info = 'genre' THEN mi.info END) AS genre_count,
        COUNT(DISTINCT CASE WHEN it.info = 'language' THEN mi.info END) AS language_count
    FROM title t
    LEFT JOIN kind_type k ON t.kind_id = k.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY t.id, t.title, t.production_year, k.kind
),
final_stats AS (
    SELECT
        movie_id,
        title,
        production_year,
        kind,
        cast_count,
        keyword_count,
        company_count,
        genre_count,
        language_count,
        AVG(cast_count) OVER (PARTITION BY kind) AS avg_cast_per_kind,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY keyword_count DESC) AS keyword_rank_in_kind
    FROM movie_stats
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    keyword_count,
    company_count,
    genre_count,
    language_count,
    avg_cast_per_kind,
    keyword_rank_in_kind
FROM final_stats
WHERE cast_count > 5
ORDER BY keyword_count DESC
LIMIT 10
