WITH
post_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_like_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY f.id
),
comment_like_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY f.id
),
member_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tag_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
),
comment_tag_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS comment_tag_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    moderator.first_name AS moderator_first_name,
    moderator.last_name AS moderator_last_name,
    COALESCE(pag.post_count, 0) AS post_count,
    COALESCE(cag.comment_count, 0) AS comment_count,
    COALESCE(plag.post_like_count, 0) AS post_like_count,
    COALESCE(clag.comment_like_count, 0) AS comment_like_count,
    COALESCE(mag.member_count, 0) AS member_count,
    COALESCE(ftag.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(ctag.comment_tag_count, 0) AS comment_tag_count,
    COALESCE(pag.avg_post_length, 0) AS avg_post_length,
    COALESCE(cag.avg_comment_length, 0) AS avg_comment_length,
    (COALESCE(pag.post_count, 0) + COALESCE(cag.comment_count, 0) + COALESCE(plag.post_like_count, 0) + COALESCE(clag.comment_like_count, 0) + COALESCE(mag.member_count, 0) + COALESCE(ftag.forum_tag_count, 0) + COALESCE(ctag.comment_tag_count, 0)) AS total_activity
FROM forum f
JOIN person moderator ON moderator.id = f.moderator_person_id
LEFT JOIN post_agg pag ON pag.forum_id = f.id
LEFT JOIN comment_agg cag ON cag.forum_id = f.id
LEFT JOIN post_like_agg plag ON plag.forum_id = f.id
LEFT JOIN comment_like_agg clag ON clag.forum_id = f.id
LEFT JOIN member_agg mag ON mag.forum_id = f.id
LEFT JOIN forum_tag_agg ftag ON ftag.forum_id = f.id
LEFT JOIN comment_tag_agg ctag ON ctag.forum_id = f.id
ORDER BY total_activity DESC
LIMIT 10
