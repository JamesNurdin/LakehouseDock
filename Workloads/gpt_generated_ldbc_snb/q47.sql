WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS post_id
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
),
forum_mod AS (
    SELECT
        f.id AS forum_id,
        p.gender AS moderator_gender
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
),
forum_comments AS (
    SELECT
        fp.forum_id,
        fp.forum_title,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id
    FROM forum_posts fp
    LEFT JOIN comment c
        ON c.parent_post_id = fp.post_id
),
post_agg AS (
    SELECT
        forum_id,
        forum_title,
        COUNT(DISTINCT post_id) AS post_count
    FROM forum_posts
    GROUP BY forum_id, forum_title
),
comment_agg AS (
    SELECT
        forum_id,
        forum_title,
        COUNT(DISTINCT comment_id) AS comment_count,
        AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id, forum_title
),
comment_likes AS (
    SELECT
        fc.forum_id,
        COUNT(plc.person_id) AS total_comment_likes
    FROM forum_comments fc
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = fc.comment_id
    GROUP BY fc.forum_id
),
comment_tags AS (
    SELECT
        fc.forum_id,
        COUNT(DISTINCT cht.tag_id) AS distinct_tag_count
    FROM forum_comments fc
    LEFT JOIN comment_has_tag_tag cht
        ON cht.comment_id = fc.comment_id
    GROUP BY fc.forum_id
),
distinct_commenters AS (
    SELECT
        forum_id,
        COUNT(DISTINCT creator_person_id) AS distinct_commenter_count
    FROM forum_comments
    WHERE creator_person_id IS NOT NULL
    GROUP BY forum_id
)
SELECT
    p.forum_id,
    p.forum_title,
    fm.moderator_gender,
    p.post_count,
    c.comment_count,
    c.avg_comment_length,
    cl.total_comment_likes,
    ct.distinct_tag_count,
    dc.distinct_commenter_count
FROM post_agg p
LEFT JOIN comment_agg c
    ON c.forum_id = p.forum_id
LEFT JOIN comment_likes cl
    ON cl.forum_id = p.forum_id
LEFT JOIN comment_tags ct
    ON ct.forum_id = p.forum_id
LEFT JOIN distinct_commenters dc
    ON dc.forum_id = p.forum_id
LEFT JOIN forum_mod fm
    ON fm.forum_id = p.forum_id
ORDER BY c.comment_count DESC
LIMIT 10
