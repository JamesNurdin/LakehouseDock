WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT plp.person_id) AS post_like_user_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT plc.person_id) AS comment_like_user_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT participant.person_id) AS participant_user_count
    FROM forum f
    LEFT JOIN (
        SELECT p.container_forum_id AS forum_id, p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT p.container_forum_id AS forum_id, c.creator_person_id AS person_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
    ) participant ON participant.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
)
SELECT
    fp.forum_id,
    fp.title,
    fp.post_count,
    fp.avg_post_length,
    fc.comment_count,
    fc.avg_comment_length,
    fpl.post_like_user_count,
    fcl.comment_like_user_count,
    fp2.participant_user_count,
    ft.tag_count
FROM forum_posts fp
LEFT JOIN forum_comments fc ON fc.forum_id = fp.forum_id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = fp.forum_id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = fp.forum_id
LEFT JOIN forum_participants fp2 ON fp2.forum_id = fp.forum_id
LEFT JOIN forum_tags ft ON ft.forum_id = fp.forum_id
ORDER BY fp.post_count DESC
LIMIT 10
