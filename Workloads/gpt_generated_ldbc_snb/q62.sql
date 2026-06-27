WITH forum_posts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS num_posts,
            AVG(p.length) AS avg_post_length,
            SUM(p.length) AS total_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    forum_comments AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS num_comments
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_post_likes AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS num_post_likes
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_comment_likes AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS num_comment_likes
        FROM person_likes_comment cl
        JOIN comment c ON cl.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_members AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS num_members
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.num_posts, 0) AS num_posts,
    COALESCE(fc.num_comments, 0) AS num_comments,
    COALESCE(fm.num_members, 0) AS num_members,
    COALESCE(fpl.num_post_likes, 0) AS num_post_likes,
    COALESCE(fcl.num_comment_likes, 0) AS num_comment_likes,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fp.total_post_length, 0) AS total_post_length
FROM forum f
LEFT JOIN forum_posts fp      ON fp.forum_id = f.id
LEFT JOIN forum_comments fc   ON fc.forum_id = f.id
LEFT JOIN forum_members fm    ON fm.forum_id = f.id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
ORDER BY num_posts DESC
LIMIT 10
