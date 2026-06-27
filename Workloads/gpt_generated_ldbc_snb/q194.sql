WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id AS moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name
    FROM person p
),
member_counts AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
tag_counts AS (
    SELECT
        fht.forum_id,
        COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
participant_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT participant_id) AS participant_count
    FROM (
        SELECT f.id AS forum_id, fhm.person_id AS participant_id
        FROM forum f
        JOIN forum_has_member_person fhm
            ON fhm.forum_id = f.id

        UNION ALL

        SELECT f.id AS forum_id, p.creator_person_id AS participant_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id

        UNION ALL

        SELECT f.id AS forum_id, c.creator_person_id AS participant_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        JOIN comment c
            ON c.parent_post_id = p.id

        UNION ALL

        SELECT f.id AS forum_id, plp.person_id AS participant_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        JOIN person_likes_post plp
            ON plp.post_id = p.id

        UNION ALL

        SELECT f.id AS forum_id, plc.person_id AS participant_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        JOIN comment c
            ON c.parent_post_id = p.id
        JOIN person_likes_comment plc
            ON plc.comment_id = c.id
    ) AS participants_raw
    GROUP BY forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.forum_creation_date,
    mi.first_name AS moderator_first_name,
    mi.last_name AS moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(plc.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(clc.comment_like_count, 0) AS comment_like_count,
    COALESCE(pc.participant_count, 0) AS participant_count
FROM forum_base fb
LEFT JOIN moderator_info mi
    ON mi.person_id = fb.moderator_person_id
LEFT JOIN member_counts mc
    ON mc.forum_id = fb.forum_id
LEFT JOIN tag_counts tc
    ON tc.forum_id = fb.forum_id
LEFT JOIN post_stats ps
    ON ps.forum_id = fb.forum_id
LEFT JOIN post_like_counts plc
    ON plc.forum_id = fb.forum_id
LEFT JOIN comment_stats cs
    ON cs.forum_id = fb.forum_id
LEFT JOIN comment_like_counts clc
    ON clc.forum_id = fb.forum_id
LEFT JOIN participant_counts pc
    ON pc.forum_id = fb.forum_id
ORDER BY participant_count DESC
LIMIT 10
