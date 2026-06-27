WITH
    posts_year AS (
        SELECT EXTRACT(year FROM p.creationdate) AS year,
               COUNT(*) AS post_count,
               AVG(p.score) AS avg_post_score,
               SUM(p.viewcount) AS total_views,
               SUM(p.answercount) AS total_answers,
               SUM(p.commentcount) AS total_comments,
               SUM(p.favoritecount) AS total_favorites
        FROM posts p
        GROUP BY EXTRACT(year FROM p.creationdate)
    ),
    comments_year AS (
        SELECT EXTRACT(year FROM p.creationdate) AS year,
               COUNT(*) AS comment_count,
               AVG(c.score) AS avg_comment_score
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY EXTRACT(year FROM p.creationdate)
    ),
    votes_year AS (
        SELECT EXTRACT(year FROM p.creationdate) AS year,
               COUNT(*) AS vote_count,
               COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_count,
               COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY EXTRACT(year FROM p.creationdate)
    ),
    badges_year AS (
        SELECT EXTRACT(year FROM b.date) AS year,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY EXTRACT(year FROM b.date)
    ),
    posthistory_year AS (
        SELECT EXTRACT(year FROM ph.creationdate) AS year,
               COUNT(*) AS posthistory_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY EXTRACT(year FROM ph.creationdate)
    ),
    postlinks_year AS (
        SELECT EXTRACT(year FROM pl.creationdate) AS year,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        GROUP BY EXTRACT(year FROM pl.creationdate)
    ),
    tags_year AS (
        SELECT EXTRACT(year FROM p.creationdate) AS year,
               COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY EXTRACT(year FROM p.creationdate)
    ),
    active_users_year AS (
        SELECT year,
               COUNT(DISTINCT userid) AS active_user_count
        FROM (
            SELECT EXTRACT(year FROM p.creationdate) AS year, p.owneruserid AS userid
            FROM posts p
            UNION ALL
            SELECT EXTRACT(year FROM c.creationdate) AS year, c.userid
            FROM comments c
            UNION ALL
            SELECT EXTRACT(year FROM v.creationdate) AS year, v.userid
            FROM votes v
            UNION ALL
            SELECT EXTRACT(year FROM b.date) AS year, b.userid
            FROM badges b
            UNION ALL
            SELECT EXTRACT(year FROM ph.creationdate) AS year, ph.userid
            FROM posthistory ph
            UNION ALL
            SELECT EXTRACT(year FROM p.creationdate) AS year, p.lasteditoruserid AS userid
            FROM posts p
        ) u
        GROUP BY year
    )
SELECT
    COALESCE(p.year, c.year, v.year, b.year, ph.year, pl.year, t.year, au.year) AS year,
    p.post_count,
    p.avg_post_score,
    p.total_views,
    p.total_answers,
    p.total_comments,
    p.total_favorites,
    c.comment_count,
    c.avg_comment_score,
    v.vote_count,
    v.upvote_count,
    v.downvote_count,
    b.badge_count,
    ph.posthistory_count,
    pl.postlink_count,
    t.tag_count,
    au.active_user_count
FROM posts_year p
FULL OUTER JOIN comments_year c ON c.year = p.year
FULL OUTER JOIN votes_year v ON v.year = p.year
FULL OUTER JOIN badges_year b ON b.year = p.year
FULL OUTER JOIN posthistory_year ph ON ph.year = p.year
FULL OUTER JOIN postlinks_year pl ON pl.year = p.year
FULL OUTER JOIN tags_year t ON t.year = p.year
FULL OUTER JOIN active_users_year au ON au.year = p.year
ORDER BY year DESC
