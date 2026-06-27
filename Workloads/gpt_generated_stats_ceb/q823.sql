WITH
    posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            AVG(viewcount) AS avg_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 3 THEN COALESCE(bountyamount, 0) ELSE 0 END) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    badges_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_excerpt_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS tag_excerpt_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS postlink_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pag.post_count, 0) AS post_count,
    COALESCE(pag.total_post_score, 0) AS total_post_score,
    COALESCE(pag.total_viewcount, 0) AS total_viewcount,
    COALESCE(pag.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(cag.comment_count, 0) AS comment_count,
    COALESCE(cag.total_comment_score, 0) AS total_comment_score,
    COALESCE(vag.vote_count, 0) AS vote_count,
    COALESCE(vag.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(bag.badge_count, 0) AS badge_count,
    COALESCE(phag.posthistory_count, 0) AS posthistory_count,
    COALESCE(tagag.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(plag.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN posts_agg pag      ON u.id = pag.user_id
LEFT JOIN comments_agg cag   ON u.id = cag.user_id
LEFT JOIN votes_agg vag      ON u.id = vag.user_id
LEFT JOIN badges_agg bag     ON u.id = bag.user_id
LEFT JOIN posthistory_agg phag ON u.id = phag.user_id
LEFT JOIN tag_excerpt_agg tagag ON u.id = tagag.user_id
LEFT JOIN postlink_agg plag  ON u.id = plag.user_id
WHERE u.reputation > 0
ORDER BY u.reputation DESC
LIMIT 10
