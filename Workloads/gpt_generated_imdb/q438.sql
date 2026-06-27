WITH runtime_per_movie AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS INTEGER) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
yearly_metrics AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(rpm.runtime_minutes) AS avg_runtime_minutes,
        AVG(kc.keyword_count) AS avg_keyword_count,
        AVG(cc.cast_count) AS avg_cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN runtime_per_movie rpm ON t.id = rpm.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    LEFT JOIN cast_counts cc ON t.id = cc.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    movie_count,
    avg_runtime_minutes,
    avg_keyword_count,
    avg_cast_count,
    ROW_NUMBER() OVER (PARTITION BY kind ORDER BY avg_runtime_minutes DESC) AS runtime_rank_within_kind
FROM yearly_metrics
ORDER BY production_year DESC, kind
