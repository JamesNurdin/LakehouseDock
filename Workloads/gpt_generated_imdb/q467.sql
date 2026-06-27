WITH title_info AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
      AND kt.kind IN ('movie', 'tvSeries')
), cast_counts AS (
    SELECT 
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
), keyword_counts AS (
    SELECT 
        mk.movie_id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT 
    ti.production_year,
    ti.kind,
    COUNT(DISTINCT ti.title_id) AS title_count,
    SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
    SUM(COALESCE(kc.keyword_count, 0)) AS total_keywords,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_title
FROM title_info ti
LEFT JOIN cast_counts cc ON ti.title_id = cc.title_id
LEFT JOIN keyword_counts kc ON ti.title_id = kc.title_id
GROUP BY ti.production_year, ti.kind
ORDER BY ti.production_year DESC, ti.kind
