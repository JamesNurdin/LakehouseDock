WITH
    posts_agg AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_views,
            COALESCE(SUM(answercount), 0) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    votes_agg AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count
        FROM votes
        GROUP BY userid
    ),
    badges_agg AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_agg AS (
        SELECT
            userid,
            COUNT(*) AS post_history_count
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_agg AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_created_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pag.total_post_score, 0) AS total_post_score,
    COALESCE(pag.post_count, 0) AS post_count,
    CASE
        WHEN COALESCE(pag.post_count, 0) = 0 THEN 0
        ELSE CAST(COALESCE(pag.total_post_score, 0) AS double) / COALESCE(pag.post_count, 0)
    END AS avg_post_score,
    COALESCE(pag.total_views, 0) AS total_views,
    COALESCE(pag.total_answers, 0) AS total_answers,
    COALESCE(cag.comment_count, 0) AS comment_count,
    COALESCE(vag.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(bag.badge_count, 0) AS badge_count,
    COALESCE(phag.post_history_count, 0) AS post_history_count,
    COALESCE(plag.postlink_created_count, 0) AS postlink_created_count,
    COALESCE(tagag.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN posts_agg pag
    ON u.id = pag.userid
LEFT JOIN comments_agg cag
    ON u.id = cag.userid
LEFT JOIN votes_agg vag
    ON u.id = vag.userid
LEFT JOIN badges_agg bag
    ON u.id = bag.userid
LEFT JOIN posthistory_agg phag
    ON u.id = phag.userid
LEFT JOIN postlinks_agg plag
    ON u.id = plag.userid
LEFT JOIN tags_agg tagag
    ON u.id = tagag.userid
ORDER BY total_post_score DESC
LIMIT 10
