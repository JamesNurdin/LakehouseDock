WITH forum_posts AS (
    SELECT
        forum.id AS forum_id,
        forum.title AS forum_title,
        post.id AS post_id,
        post.length AS post_length,
        post.creator_person_id AS post_creator_id
    FROM forum
    JOIN post ON post.container_forum_id = forum.id
),
post_likes AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(person_likes_post.person_id) AS likes_count
    FROM person_likes_post
    JOIN post ON person_likes_post.post_id = post.id
    GROUP BY post.container_forum_id
),
post_tags AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT post_has_tag_tag.tag_id) AS distinct_tag_count
    FROM post_has_tag_tag
    JOIN post ON post_has_tag_tag.post_id = post.id
    GROUP BY post.container_forum_id
),
post_comments AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(comment.id) AS comment_count,
        SUM(comment.length) AS total_comment_length,
        COUNT(DISTINCT comment.creator_person_id) AS distinct_commenter_count
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
post_creators AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT post.creator_person_id) AS distinct_post_creator_count
    FROM post
    GROUP BY post.container_forum_id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    COUNT(DISTINCT fp.post_id) AS post_count,
    SUM(fp.post_length) AS total_post_length,
    COALESCE(pl.likes_count, 0) AS total_likes,
    COALESCE(pt.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(pc.comment_count, 0) AS comment_count,
    COALESCE(pc.total_comment_length, 0) AS total_comment_length,
    CASE WHEN COALESCE(pc.comment_count, 0) > 0 THEN COALESCE(pc.total_comment_length, 0) / CAST(COALESCE(pc.comment_count, 0) AS double) ELSE NULL END AS avg_comment_length,
    COALESCE(pc.distinct_commenter_count, 0) AS distinct_commenter_count,
    COALESCE(pc2.distinct_post_creator_count, 0) AS distinct_post_creator_count,
    CASE WHEN COUNT(DISTINCT fp.post_id) > 0 THEN SUM(fp.post_length) / CAST(COUNT(DISTINCT fp.post_id) AS double) ELSE NULL END AS avg_post_length,
    CASE WHEN COUNT(DISTINCT fp.post_id) > 0 THEN COALESCE(pl.likes_count, 0) / CAST(COUNT(DISTINCT fp.post_id) AS double) ELSE NULL END AS avg_likes_per_post,
    CASE WHEN COUNT(DISTINCT fp.post_id) > 0 THEN COALESCE(pt.distinct_tag_count, 0) / CAST(COUNT(DISTINCT fp.post_id) AS double) ELSE NULL END AS avg_tags_per_post
FROM forum_posts fp
LEFT JOIN post_likes pl ON fp.forum_id = pl.forum_id
LEFT JOIN post_tags pt ON fp.forum_id = pt.forum_id
LEFT JOIN post_comments pc ON fp.forum_id = pc.forum_id
LEFT JOIN post_creators pc2 ON fp.forum_id = pc2.forum_id
GROUP BY
    fp.forum_id,
    fp.forum_title,
    pl.likes_count,
    pt.distinct_tag_count,
    pc.comment_count,
    pc.total_comment_length,
    pc.distinct_commenter_count,
    pc2.distinct_post_creator_count
ORDER BY post_count DESC
LIMIT 10
