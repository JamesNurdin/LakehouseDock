WITH
    posts AS (
        SELECT f.id AS forum_id,
               p.id AS post_id,
               p.length AS post_length
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
    ),
    comments AS (
        SELECT f.id AS forum_id,
               c.id AS comment_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ),
    post_likes AS (
        SELECT f.id AS forum_id,
               pl.person_id AS liker_id
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ),
    comment_likes AS (
        SELECT f.id AS forum_id,
               cl.person_id AS liker_id
        FROM person_likes_comment cl
        JOIN comment c ON cl.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ),
    members AS (
        SELECT f.id AS forum_id,
               fm.person_id AS member_id
        FROM forum_has_member_person fm
        JOIN forum f ON fm.forum_id = f.id
    ),
    tag_counts AS (
        SELECT f.id AS forum_id,
               t.id AS tag_id,
               t.name AS tag_name,
               COUNT(DISTINCT p.id) AS post_cnt
        FROM post_has_tag_tag pt
        JOIN post p ON pt.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        JOIN tag t ON pt.tag_id = t.id
        GROUP BY f.id, t.id, t.name
    ),
    ranked_tags AS (
        SELECT forum_id,
               tag_name,
               post_cnt,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY post_cnt DESC, tag_name) AS rn
        FROM tag_counts
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(m.total_members, 0) AS distinct_members,
    COALESCE(tc.total_tags, 0) AS distinct_tags,
    COALESCE(pl.total_post_likes, 0) AS total_likes_on_posts,
    COALESCE(cl.total_comment_likes, 0) AS total_likes_on_comments,
    MAX(CASE WHEN rt.rn = 1 THEN rt.tag_name END) AS top_tag_1_name,
    MAX(CASE WHEN rt.rn = 1 THEN rt.post_cnt END) AS top_tag_1_post_count,
    MAX(CASE WHEN rt.rn = 2 THEN rt.tag_name END) AS top_tag_2_name,
    MAX(CASE WHEN rt.rn = 2 THEN rt.post_cnt END) AS top_tag_2_post_count,
    MAX(CASE WHEN rt.rn = 3 THEN rt.tag_name END) AS top_tag_3_name,
    MAX(CASE WHEN rt.rn = 3 THEN rt.post_cnt END) AS top_tag_3_post_count
FROM forum f
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT post_id) AS total_posts,
           AVG(post_length) AS avg_post_length
    FROM posts
    GROUP BY forum_id
) p ON f.id = p.forum_id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS total_comments
    FROM comments
    GROUP BY forum_id
) c ON f.id = c.forum_id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT member_id) AS total_members
    FROM members
    GROUP BY forum_id
) m ON f.id = m.forum_id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS total_tags
    FROM tag_counts
    GROUP BY forum_id
) tc ON f.id = tc.forum_id
LEFT JOIN (
    SELECT forum_id,
           COUNT(*) AS total_post_likes
    FROM post_likes
    GROUP BY forum_id
) pl ON f.id = pl.forum_id
LEFT JOIN (
    SELECT forum_id,
           COUNT(*) AS total_comment_likes
    FROM comment_likes
    GROUP BY forum_id
) cl ON f.id = cl.forum_id
LEFT JOIN ranked_tags rt ON f.id = rt.forum_id AND rt.rn <= 3
GROUP BY f.id, f.title, f.creation_date,
         p.total_posts, p.avg_post_length,
         c.total_comments,
         m.total_members,
         tc.total_tags,
         pl.total_post_likes,
         cl.total_comment_likes
ORDER BY total_posts DESC
LIMIT 100
