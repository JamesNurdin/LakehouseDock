/*
   Analytical query: summary of activity per forum
   - Number of posts and average post length
   - Number of comments and average comment length
   - Number of distinct members
   - Number of distinct tags directly attached to the forum
   - Number of distinct tags used by posts in the forum
   - Number of distinct persons who liked posts in the forum
*/
WITH forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tags AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pl.person_id) AS like_count
    FROM post p
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(ft.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(pt.post_tag_count, 0) AS post_tag_count,
    COALESCE(pl.like_count, 0) AS like_count
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_tags ft ON ft.forum_id = f.id
LEFT JOIN post_tags pt ON pt.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
ORDER BY post_count DESC
LIMIT 20
