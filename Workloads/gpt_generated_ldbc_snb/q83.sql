WITH forum_members AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS post_like_count
    FROM post p
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
forum_tag_usage AS (
    SELECT
        p.container_forum_id AS forum_id,
        pt.tag_id,
        COUNT(*) AS tag_usage
    FROM post_has_tag_tag pt
    JOIN post p
        ON pt.post_id = p.id
    GROUP BY p.container_forum_id, pt.tag_id
),
forum_top_tags_ranked AS (
    SELECT
        forum_id,
        tag_id,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM forum_tag_usage
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    (
        SELECT array_agg(tag_id)
        FROM forum_top_tags_ranked t
        WHERE t.forum_id = f.id
          AND t.rn <= 3
    ) AS top_3_tag_ids
FROM forum f
LEFT JOIN forum_members m
    ON m.forum_id = f.id
LEFT JOIN forum_posts p
    ON p.forum_id = f.id
LEFT JOIN forum_post_likes pl
    ON pl.forum_id = f.id
LEFT JOIN forum_comments c
    ON c.forum_id = f.id
LEFT JOIN forum_comment_likes cl
    ON cl.forum_id = f.id
ORDER BY member_count DESC, forum_id
