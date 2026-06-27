WITH
    title_base AS (
        SELECT
            t.id AS title_id,
            t.kind_id,
            t.production_year
        FROM title t
        WHERE t.production_year >= 2000
    ),
    keyword_per_title AS (
        SELECT
            mk.movie_id AS title_id,
            COUNT(DISTINCT k.id) AS keyword_cnt
        FROM movie_keyword mk
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY mk.movie_id
    ),
    info_per_title AS (
        SELECT
            mi.movie_id AS title_id,
            AVG(mi.note) AS avg_note
        FROM movie_info_idx mi
        GROUP BY mi.movie_id
    ),
    title_aggregated AS (
        SELECT
            tb.title_id,
            tb.kind_id,
            tb.production_year,
            COALESCE(kpt.keyword_cnt, 0) AS keyword_cnt,
            ipt.avg_note
        FROM title_base tb
        LEFT JOIN keyword_per_title kpt ON tb.title_id = kpt.title_id
        LEFT JOIN info_per_title ipt ON tb.title_id = ipt.title_id
    ),
    kind_agg AS (
        SELECT
            kt.kind,
            COUNT(*) AS title_count,
            AVG(ta.production_year) AS avg_production_year,
            SUM(ta.keyword_cnt) AS total_keyword_assignments,
            AVG(ta.keyword_cnt) AS avg_keywords_per_title,
            AVG(ta.avg_note) AS avg_note_per_title
        FROM title_aggregated ta
        JOIN kind_type kt ON ta.kind_id = kt.id
        GROUP BY kt.kind
    ),
    distinct_keyword_per_kind AS (
        SELECT
            kt.kind,
            COUNT(DISTINCT k.id) AS distinct_keyword_count
        FROM title_aggregated ta
        JOIN kind_type kt ON ta.kind_id = kt.id
        LEFT JOIN movie_keyword mk ON mk.movie_id = ta.title_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY kt.kind
    )
SELECT
    ka.kind,
    ka.title_count,
    ka.avg_production_year,
    ka.total_keyword_assignments,
    ka.avg_keywords_per_title,
    ka.avg_note_per_title,
    COALESCE(dk.distinct_keyword_count, 0) AS distinct_keyword_count
FROM kind_agg ka
LEFT JOIN distinct_keyword_per_kind dk ON ka.kind = dk.kind
ORDER BY ka.title_count DESC
