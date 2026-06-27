WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT c.id) AS comment_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id, f.title
),
forum_member_tags AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT fm.person_id) AS member_interest_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = fm.person_id
    JOIN tag t
        ON t.id = pit.tag_id
    GROUP BY f.id, t.id, t.name
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM post p
    JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM comment c
    JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.post_count,
    fs.comment_count,
    fs.avg_post_length,
    COALESCE(pl.post_like_count, 0) AS total_post_likes,
    COALESCE(cl.comment_like_count, 0) AS total_comment_likes,
    mc.member_count,
    fm.tag_id,
    fm.tag_name,
    fm.member_interest_count,
    CASE WHEN fs.post_count > 0 THEN COALESCE(pl.post_like_count, 0) / CAST(fs.post_count AS double) END AS avg_likes_per_post,
    CASE WHEN fs.post_count > 0 THEN fs.comment_count / CAST(fs.post_count AS double) END AS avg_comments_per_post,
    CASE WHEN fs.comment_count > 0 THEN COALESCE(cl.comment_like_count, 0) / CAST(fs.comment_count AS double) END AS avg_likes_per_comment
FROM forum_stats fs
LEFT JOIN post_likes pl
    ON pl.forum_id = fs.forum_id
LEFT JOIN comment_likes cl
    ON cl.forum_id = fs.forum_id
LEFT JOIN forum_member_counts mc
    ON mc.forum_id = fs.forum_id
LEFT JOIN forum_member_tags fm
    ON fm.forum_id = fs.forum_id
ORDER BY fs.forum_id, fm.member_interest_count DESC
