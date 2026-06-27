WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(pl.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),

comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(cl.person_id) AS comment_like_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
),

participant_stats AS (
    SELECT
        participants.forum_id,
        COUNT(DISTINCT participants.person_id) AS distinct_participant_count
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            c.creator_person_id AS person_id
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            pl.person_id AS person_id
        FROM post p
        JOIN person_likes_post pl
            ON pl.post_id = p.id
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            cl.person_id AS person_id
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        JOIN person_likes_comment cl
            ON cl.comment_id = c.id
    ) AS participants
    GROUP BY participants.forum_id
)

SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ps.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_like_count, 0) AS comment_like_count,
    COALESCE(part.distinct_participant_count, 0) AS distinct_participant_count
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN participant_stats part
    ON part.forum_id = f.id
ORDER BY (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0)) DESC
LIMIT 10
