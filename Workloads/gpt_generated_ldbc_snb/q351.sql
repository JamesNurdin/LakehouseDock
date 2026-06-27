WITH post_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
    FROM post p
    GROUP BY p.container_forum_id
),
member_agg AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
moderator_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        p.gender AS moderator_gender,
        p.id AS moderator_person_id
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
)
SELECT
    mi.forum_id,
    mi.title,
    mi.creation_date,
    mi.moderator_gender,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(pa.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(ma.member_count, 0) AS member_count
FROM moderator_info mi
LEFT JOIN post_agg pa
    ON mi.forum_id = pa.forum_id
LEFT JOIN member_agg ma
    ON mi.forum_id = ma.forum_id
ORDER BY post_count DESC
LIMIT 10
