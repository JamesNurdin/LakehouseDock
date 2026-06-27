WITH rating_per_movie AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_stats AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_cnt,
        AVG(rpm.rating) AS avg_rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN rating_per_movie rpm ON t.id = rpm.movie_id
    GROUP BY t.production_year, kt.kind
),
actor_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT n.id) AS actor_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY t.production_year, kt.kind
),
company_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT cn.id) AS company_cnt
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title t ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY t.production_year, kt.kind
)
SELECT
    ms.production_year,
    ms.kind,
    ms.movie_cnt,
    ms.avg_rating,
    ac.actor_cnt,
    cc.company_cnt,
    kc.keyword_cnt
FROM movie_stats ms
LEFT JOIN actor_counts ac
    ON ms.production_year = ac.production_year AND ms.kind = ac.kind
LEFT JOIN company_counts cc
    ON ms.production_year = cc.production_year AND ms.kind = cc.kind
LEFT JOIN keyword_counts kc
    ON ms.production_year = kc.production_year AND ms.kind = kc.kind
ORDER BY ms.production_year DESC, ms.kind
