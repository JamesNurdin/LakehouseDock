WITH movie_ratings AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        CAST(mi.info AS double) AS rating
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'rating'
      AND t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
award_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS award_cast_count
    FROM cast_info ci
    JOIN name n ON n.id = ci.person_id
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON it.id = pi.info_type_id
    WHERE it.info = 'award'
    GROUP BY ci.movie_id
)
SELECT
    mr.production_year,
    COUNT(*) AS num_movies,
    AVG(mr.rating) AS avg_rating,
    SUM(cc.cast_count) AS total_cast_members,
    SUM(COALESCE(ac.award_cast_count, 0)) AS total_award_cast_members,
    AVG(
        CASE
            WHEN cc.cast_count > 0 THEN CAST(COALESCE(ac.award_cast_count, 0) AS double) / cc.cast_count
            ELSE NULL
        END
    ) AS avg_award_ratio_per_movie
FROM movie_ratings mr
JOIN cast_counts cc ON cc.title_id = mr.title_id
LEFT JOIN award_counts ac ON ac.title_id = mr.title_id
GROUP BY mr.production_year
ORDER BY mr.production_year DESC
LIMIT 10
