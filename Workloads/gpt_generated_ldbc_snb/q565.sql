WITH forum_info AS (
    SELECT id AS forum_id,
           title,
           moderator_person_id
    FROM forum
),
post_stats AS (
    SELECT container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
participant_union AS (
    SELECT p.container_forum_id AS forum_id,
           p.creator_person_id AS person_id
    FROM post p
    UNION ALL
    SELECT p.container_forum_id AS forum_id,
           c.creator_person_id AS person_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    UNION ALL
    SELECT p.container_forum_id AS forum_id,
           pl.person_id AS person_id
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
),
participant_stats AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS participant_count
    FROM participant_union
    GROUP BY forum_id
),
moderator_info AS (
    SELECT p.id AS moderator_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM person p
)
SELECT fi.forum_id,
       fi.title,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pt.participant_count, 0) AS participant_count,
       mi.moderator_first_name,
       mi.moderator_last_name
FROM forum_info fi
LEFT JOIN post_stats ps ON ps.forum_id = fi.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = fi.forum_id
LEFT JOIN participant_stats pt ON pt.forum_id = fi.forum_id
LEFT JOIN moderator_info mi ON mi.moderator_id = fi.moderator_person_id
ORDER BY participant_count DESC
LIMIT 10
