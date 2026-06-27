WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_cnt
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id
),
company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS company_cnt,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production companies' THEN cn.id END) AS production_company_cnt,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distributors' THEN cn.id END) AS distributor_cnt
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id
),
keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id
)
SELECT *
FROM (
    SELECT
        t.title,
        kt.kind AS movie_kind,
        t.production_year,
        cc.cast_member_cnt,
        co.company_cnt,
        co.production_company_cnt,
        co.distributor_cnt,
        kw.keyword_cnt,
        ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY cc.cast_member_cnt DESC) AS rank_in_kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_counts cc ON cc.movie_id = t.id
    JOIN company_counts co ON co.movie_id = t.id
    JOIN keyword_counts kw ON kw.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
) ranked
WHERE rank_in_kind <= 5
ORDER BY cast_member_cnt DESC
