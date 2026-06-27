WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS number_of_members
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS num_posts
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
post_likes_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS total_post_likes
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
comment_likes_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS total_comment_likes
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
post_tags_agg AS (
    SELECT
        f.id AS forum_id,
        p.id AS post_id,
        COUNT(DISTINCT pt.tag_id) AS tag_count
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY f.id, p.id
),
avg_tags_per_forum AS (
    SELECT
        forum_id,
        AVG(tag_count) AS avg_tags_per_post
    FROM post_tags_agg
    GROUP BY forum_id
)

SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(m.number_of_members, 0) AS number_of_members,
    COALESCE(p.num_posts, 0) AS number_of_posts,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(a.avg_tags_per_post, 0) AS avg_tags_per_post
FROM forum f
LEFT JOIN forum_members m
    ON m.forum_id = f.id
LEFT JOIN forum_posts_agg p
    ON p.forum_id = f.id
LEFT JOIN post_likes_agg pl
    ON pl.forum_id = f.id
LEFT JOIN comment_likes_agg cl
    ON cl.forum_id = f.id
LEFT JOIN avg_tags_per_forum a
    ON a.forum_id = f.id
ORDER BY total_post_likes DESC
LIMIT 100
