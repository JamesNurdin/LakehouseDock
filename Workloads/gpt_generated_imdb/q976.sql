WITH
    keyword_counts AS (
        SELECT
            movie_id,
            COUNT(*) AS keyword_cnt
        FROM movie_keyword
        GROUP BY movie_id
    ),
    numeric_info_agg AS (
        SELECT
            movie_id,
            info_type_id,
            AVG(note) AS avg_note
        FROM movie_info_idx
        GROUP BY movie_id, info_type_id
    ),
    person_counts AS (
        SELECT
            info_type_id,
            COUNT(DISTINCT person_id) AS person_cnt
        FROM person_info
        GROUP BY info_type_id
    )
SELECT
    it.info AS info_type,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    AVG(ni.avg_note) AS avg_numeric_note,
    COALESCE(MAX(pc.person_cnt), 0) AS person_count
FROM info_type it
LEFT JOIN numeric_info_agg ni
    ON ni.info_type_id = it.id
LEFT JOIN title t
    ON t.id = ni.movie_id
LEFT JOIN keyword_counts kc
    ON kc.movie_id = t.id
LEFT JOIN person_counts pc
    ON pc.info_type_id = it.id
GROUP BY it.info
ORDER BY movie_count DESC
LIMIT 10
