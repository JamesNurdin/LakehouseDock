WITH
    cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT mc.company_id) AS company_count,
               COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        GROUP BY mc.movie_id
    ),
    info_counts AS (
        SELECT mi.movie_id,
               COUNT(*) AS info_entry_count
        FROM movie_info mi
        GROUP BY mi.movie_id
    ),
    info_idx_sums AS (
        SELECT mix.movie_id,
               SUM(mix.note) AS total_note_sum
        FROM movie_info_idx mix
        GROUP BY mix.movie_id
    )
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       COALESCE(cm.company_count, 0) AS company_count,
       COALESCE(cm.production_company_count, 0) AS production_company_count,
       COALESCE(ic.info_entry_count, 0) AS info_entry_count,
       COALESCE(ii.total_note_sum, 0) AS total_note_sum,
       ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY COALESCE(cc.cast_count, 0) DESC) AS rank_in_kind
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN company_counts cm ON t.id = cm.movie_id
LEFT JOIN info_counts ic ON t.id = ic.movie_id
LEFT JOIN info_idx_sums ii ON t.id = ii.movie_id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC, keyword_count DESC
LIMIT 10
