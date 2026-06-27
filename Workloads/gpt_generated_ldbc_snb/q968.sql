WITH comment_likes AS (
    SELECT
        plc.comment_id,
        COUNT(DISTINCT plc.person_id) AS likes_count
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
),
comment_base AS (
    SELECT
        c.id AS comment_id,
        c.parent_post_id,
        c.creator_person_id,
        c.length AS comment_length
    FROM comment c
),
forum_comment_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(cb.comment_id) AS total_comments,
        AVG(cb.comment_length) AS avg_comment_length,
        COALESCE(SUM(cl.likes_count), 0) AS total_likes,
        COUNT(DISTINCT cb.creator_person_id) AS distinct_commenters
    FROM comment_base cb
    LEFT JOIN comment_likes cl ON cl.comment_id = cb.comment_id
    JOIN post p ON p.id = cb.parent_post_id
    JOIN forum f ON f.id = p.container_forum_id
    GROUP BY f.id, f.title
),
forum_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT cht.tag_id) AS distinct_tags_used
    FROM comment_base cb
    JOIN post p ON p.id = cb.parent_post_id
    JOIN forum f ON f.id = p.container_forum_id
    JOIN comment_has_tag_tag cht ON cht.comment_id = cb.comment_id
    GROUP BY f.id
)
SELECT
    fca.forum_id,
    fca.forum_title,
    fca.total_comments,
    fca.avg_comment_length,
    fca.total_likes,
    fca.distinct_commenters,
    COALESCE(ft.distinct_tags_used, 0) AS distinct_tags_used
FROM forum_comment_agg fca
LEFT JOIN forum_tags ft ON ft.forum_id = fca.forum_id
ORDER BY fca.total_comments DESC
LIMIT 10
