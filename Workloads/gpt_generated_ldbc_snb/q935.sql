WITH post_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(*) AS post_count,
        AVG(post.length) AS avg_post_length
    FROM post
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
comment_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(comment.id) AS comment_count,
        AVG(comment.length) AS avg_comment_length
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
like_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(*) AS like_count
    FROM person_likes_post
    JOIN post ON person_likes_post.post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
member_agg AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    JOIN forum ON forum_has_member_person.forum_id = forum.id
    GROUP BY forum.id
),
tag_counts AS (
    SELECT
        forum.id AS forum_id,
        post_has_tag_tag.tag_id,
        COUNT(*) AS tag_count
    FROM post_has_tag_tag
    JOIN post ON post_has_tag_tag.post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id, post_has_tag_tag.tag_id
),
top_tag AS (
    SELECT
        forum_id,
        tag_id AS top_tag_id,
        tag_count AS top_tag_count
    FROM (
        SELECT
            forum_id,
            tag_id,
            tag_count,
            ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS rn
        FROM tag_counts
    ) t
    WHERE rn = 1
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    pa.post_count,
    pa.avg_post_length,
    ca.comment_count,
    ca.avg_comment_length,
    la.like_count,
    ma.member_count,
    tt.top_tag_id,
    tt.top_tag_count
FROM forum f
LEFT JOIN post_agg pa ON f.id = pa.forum_id
LEFT JOIN comment_agg ca ON f.id = ca.forum_id
LEFT JOIN like_agg la ON f.id = la.forum_id
LEFT JOIN member_agg ma ON f.id = ma.forum_id
LEFT JOIN top_tag tt ON f.id = tt.forum_id
ORDER BY f.id
