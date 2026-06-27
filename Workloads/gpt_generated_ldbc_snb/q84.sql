WITH
comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
like_given_stats AS (
    SELECT
        plc.person_id AS person_id,
        COUNT(*) AS likes_given
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
likes_received_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS likes_received
    FROM person_likes_comment plc
    JOIN comment c
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
friend_edges AS (
    SELECT
        pk.person1_id AS person_id,
        pk.person2_id AS friend_id
    FROM person_knows_person pk
    UNION ALL
    SELECT
        pk.person2_id AS person_id,
        pk.person1_id AS friend_id
    FROM person_knows_person pk
),
friend_stats AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS total_friends
    FROM friend_edges
    GROUP BY person_id
),
forum_stats AS (
    SELECT
        f.moderator_person_id AS person_id,
        COUNT(*) AS forums_moderated
    FROM forum f
    GROUP BY f.moderator_person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lgs.likes_given, 0) AS likes_given,
    COALESCE(lrs.likes_received, 0) AS likes_received,
    COALESCE(fs.total_friends, 0) AS total_friends,
    COALESCE(fms.forums_moderated, 0) AS forums_moderated,
    (COALESCE(cs.comment_count, 0) + COALESCE(lgs.likes_given, 0) + COALESCE(lrs.likes_received, 0) + COALESCE(fms.forums_moderated, 0)) AS total_activity
FROM person p
LEFT JOIN comment_stats cs
    ON cs.person_id = p.id
LEFT JOIN like_given_stats lgs
    ON lgs.person_id = p.id
LEFT JOIN likes_received_stats lrs
    ON lrs.person_id = p.id
LEFT JOIN friend_stats fs
    ON fs.person_id = p.id
LEFT JOIN forum_stats fms
    ON fms.person_id = p.id
ORDER BY total_activity DESC, total_friends DESC
LIMIT 100
