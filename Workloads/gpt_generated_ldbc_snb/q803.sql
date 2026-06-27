/*
   Analytical query for LDBC SNB BI (sf0003) using Iceberg tables via Trino.
   For each forum it returns basic forum info, member counts, post statistics,
   and the most common language used in its posts.
*/
WITH member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count,
        MIN(creation_date) AS earliest_member_join_date
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        container_forum_id,
        COUNT(*) AS post_count,
        AVG(length) AS avg_post_length,
        COUNT(DISTINCT creator_person_id) AS distinct_creator_count,
        COUNT(CASE WHEN image_file IS NOT NULL THEN 1 END) AS image_post_count,
        MIN(creation_date) AS earliest_post_date,
        MAX(creation_date) AS latest_post_date
    FROM post
    GROUP BY container_forum_id
),
language_modes AS (
    SELECT
        container_forum_id,
        language,
        cnt
    FROM (
        SELECT
            container_forum_id,
            language,
            COUNT(*) AS cnt,
            ROW_NUMBER() OVER (PARTITION BY container_forum_id ORDER BY COUNT(*) DESC) AS rn
        FROM post
        WHERE language IS NOT NULL
        GROUP BY container_forum_id, language
    ) t
    WHERE rn = 1
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date AS forum_creation_date,
    f.moderator_person_id,
    COALESCE(m.member_count, 0) AS member_count,
    m.earliest_member_join_date,
    COALESCE(p.post_count, 0) AS post_count,
    p.avg_post_length,
    p.distinct_creator_count,
    p.image_post_count,
    p.earliest_post_date,
    p.latest_post_date,
    lm.language AS most_common_language,
    lm.cnt AS most_common_language_post_count
FROM forum f
LEFT JOIN member_counts m
    ON m.forum_id = f.id
LEFT JOIN post_stats p
    ON p.container_forum_id = f.id
LEFT JOIN language_modes lm
    ON lm.container_forum_id = f.id
ORDER BY post_count DESC
LIMIT 100
