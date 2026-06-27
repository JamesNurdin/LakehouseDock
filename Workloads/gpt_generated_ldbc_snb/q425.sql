-- Analytical query: forum activity summary (posts, comments, tags, members, likes)
WITH forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS total_posts,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS total_comments,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_post_tags
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY f.id
),
forum_comment_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS total_members
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS total_post_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS total_comment_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       COALESCE(fp.total_posts, 0) AS total_posts,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fc.total_comments, 0) AS total_comments,
       COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(fpt.distinct_post_tags, 0) AS distinct_post_tags,
       COALESCE(fct.distinct_comment_tags, 0) AS distinct_comment_tags,
       COALESCE(fm.total_members, 0) AS total_members,
       COALESCE(fpl.total_post_likes, 0) AS total_post_likes,
       COALESCE(fcl.total_comment_likes, 0) AS total_comment_likes
FROM forum f
LEFT JOIN forum_posts fp        ON fp.forum_id = f.id
LEFT JOIN forum_comments fc    ON fc.forum_id = f.id
LEFT JOIN forum_post_tags fpt   ON fpt.forum_id = f.id
LEFT JOIN forum_comment_tags fct ON fct.forum_id = f.id
LEFT JOIN forum_members fm      ON fm.forum_id = f.id
LEFT JOIN forum_post_likes fpl  ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
ORDER BY total_posts DESC
LIMIT 10
