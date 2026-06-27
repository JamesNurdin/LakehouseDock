WITH title_stats AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS info_type_1_cnt
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    title_cnt,
    avg_company_per_title,
    avg_keyword_per_title,
    total_info_type_1,
    ROW_NUMBER() OVER (PARTITION BY kind ORDER BY title_cnt DESC) AS rank_by_title_cnt
FROM (
    SELECT
        production_year,
        kind,
        COUNT(*) AS title_cnt,
        AVG(company_cnt) AS avg_company_per_title,
        AVG(keyword_cnt) AS avg_keyword_per_title,
        SUM(info_type_1_cnt) AS total_info_type_1
    FROM title_stats
    WHERE production_year IS NOT NULL
    GROUP BY production_year, kind
) agg
ORDER BY production_year DESC, kind
