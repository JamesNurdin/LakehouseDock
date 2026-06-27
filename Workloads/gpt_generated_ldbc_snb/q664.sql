WITH
    posts_per_forum AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS post_count
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comments_per_forum AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    post_likes_per_forum AS (
        SELECT
            f.id AS forum_id,
            COUNT(pl.person_id) AS post_like_count
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_likes_per_forum AS (
        SELECT
            f.id AS forum_id,
            COUNT(cl.person_id) AS comment_like_count
        FROM person_likes_comment cl
        JOIN comment c ON cl.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    members_per_forum AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        JOIN forum f ON fm.forum_id = f.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(pf.post_count, 0) AS post_count,
    COALESCE(cf.comment_count, 0) AS comment_count,
    COALESCE(cf.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(plf.post_like_count, 0) AS post_like_count,
    COALESCE(clf.comment_like_count, 0) AS comment_like_count,
    COALESCE(mf.member_count, 0) AS member_count,
    (COALESCE(pf.post_count, 0) + COALESCE(cf.comment_count, 0) + COALESCE(plf.post_like_count, 0) + COALESCE(clf.comment_like_count, 0)) AS total_activity
FROM forum f
LEFT JOIN posts_per_forum pf ON f.id = pf.forum_id
LEFT JOIN comments_per_forum cf ON f.id = cf.forum_id
LEFT JOIN post_likes_per_forum plf ON f.id = plf.forum_id
LEFT JOIN comment_likes_per_forum clf ON f.id = clf.forum_id
LEFT JOIN members_per_forum mf ON f.id = mf.forum_id
ORDER BY total_activity DESC
LIMIT 10
