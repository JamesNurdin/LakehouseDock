WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        COUNT(DISTINCT ct.kind) AS distinct_company_types,
        COUNT(DISTINCT k.keyword) AS distinct_keywords,
        AVG(r.rating) AS avg_rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT mi.movie_id, CAST(mi.info AS double) AS rating
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
    ) r ON r.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    distinct_cast,
    distinct_characters,
    distinct_companies,
    distinct_company_types,
    distinct_keywords,
    avg_rating,
    rank() OVER (ORDER BY distinct_cast DESC) AS cast_rank
FROM movie_metrics
ORDER BY distinct_cast DESC
LIMIT 10
