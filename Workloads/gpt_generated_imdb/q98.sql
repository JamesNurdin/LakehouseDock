/*
  Analytical query: Top 20 keywords (across all kinds) for movies released from the year 2000 onward.
  For each keyword we compute:
    • Number of distinct movies that have the keyword (movie_count)
    • Average production year of those movies (avg_production_year)
    • Average number of distinct info_type_id entries per movie from movie_info_idx (avg_distinct_info_type_cnt_idx)
    • Average number of distinct info_type_id entries per movie from movie_info (avg_distinct_info_type_cnt_info)
    • Average of the numeric "note" field for info_type_id = 101 (avg_note_type_101) – a placeholder for a numeric attribute such as rating.
  The query respects all join rules and uses only the selected tables.
*/
WITH movie_info_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_cnt,
        AVG(CASE WHEN info_type_id = 101 THEN note END) AS avg_note_type_101
    FROM movie_info_idx
    GROUP BY movie_id
),
movie_info_cnt AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_cnt_info
    FROM movie_info
    GROUP BY movie_id
),
keyword_stats AS (
    SELECT
        kt.kind,
        kw.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        AVG(mi.distinct_info_type_cnt) AS avg_distinct_info_type_cnt_idx,
        AVG(mi_cnt.distinct_info_type_cnt_info) AS avg_distinct_info_type_cnt_info,
        AVG(mi.avg_note_type_101) AS avg_note_type_101
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_info_agg mi ON mi.movie_id = t.id
    LEFT JOIN movie_info_cnt mi_cnt ON mi_cnt.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY kt.kind, kw.id, kw.keyword
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_production_year,
    avg_distinct_info_type_cnt_idx,
    avg_distinct_info_type_cnt_info,
    avg_note_type_101
FROM keyword_stats
ORDER BY movie_count DESC
LIMIT 20
