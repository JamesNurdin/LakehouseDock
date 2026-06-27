WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
            SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
            SUM(score) AS total_score,
            AVG(viewcount) AS avg_viewcount,
            SUM(commentcount) AS total_comment_received,
            MAX(creationdate) AS latest_post_date
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_made AS (
        SELECT
            userid,
            COUNT(*) AS comment_made_count
        FROM comments
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast_count,
            COALESCE(SUM(bountyamount), 0) AS total_bounty_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_as_source AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_as_source_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_as_target AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_as_target_count
        FROM postlinks pl
        JOIN posts p
            ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(up.total_comment_received, 0) AS total_comment_received,
    COALESCE(ucm.comment_made_count, 0) AS comment_made_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pls.link_as_source_count, 0) AS link_as_source_count,
    COALESCE(plt.link_as_target_count, 0) AS link_as_target_count,
    up.latest_post_date
FROM users u
LEFT JOIN user_posts up
    ON u.id = up.userid
LEFT JOIN user_comments_made ucm
    ON u.id = ucm.userid
LEFT JOIN user_badges ub
    ON u.id = ub.userid
LEFT JOIN votes_cast vc
    ON u.id = vc.userid
LEFT JOIN votes_received vr
    ON u.id = vr.userid
LEFT JOIN user_posthistory uph
    ON u.id = uph.userid
LEFT JOIN postlinks_as_source pls
    ON u.id = pls.userid
LEFT JOIN postlinks_as_target plt
    ON u.id = plt.userid
ORDER BY u.reputation DESC
LIMIT 100
