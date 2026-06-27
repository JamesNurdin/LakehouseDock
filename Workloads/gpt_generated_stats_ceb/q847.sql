WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS posts_owned,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(answercount) AS total_answercount,
            SUM(commentcount) AS total_commentcount,
            SUM(favoritecount) AS total_favoritecount
        FROM stats_ceb_sf1.posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS posts_edited,
            MAX(creationdate) AS latest_edit_date
        FROM stats_ceb_sf1.posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comments_made,
            SUM(score) AS total_comment_score,
            MAX(creationdate) AS latest_comment_date
        FROM stats_ceb_sf1.comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            COUNT(DISTINCT postid) AS distinct_posts_voted,
            MAX(creationdate) AS latest_vote_date
        FROM stats_ceb_sf1.votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received,
            COUNT(DISTINCT v.postid) AS distinct_posts_received_votes
        FROM stats_ceb_sf1.votes v
        JOIN stats_ceb_sf1.posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badges_earned,
            MIN(date) AS earliest_badge_date,
            MAX(date) AS latest_badge_date
        FROM stats_ceb_sf1.badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_events,
            COUNT(DISTINCT postid) AS distinct_posts_hist
        FROM stats_ceb_sf1.posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    u.views AS user_views,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.distinct_posts_received_votes, 0) AS distinct_posts_received_votes,
    COALESCE(b.badges_earned, 0) AS badges_earned,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    COALESCE(ph.distinct_posts_hist, 0) AS distinct_posts_hist,
    (COALESCE(up.posts_owned, 0) * 2
     + COALESCE(uc.comments_made, 0)
     + COALESCE(vc.votes_cast, 0)
     + COALESCE(vr.votes_received, 0)
     + COALESCE(b.badges_earned, 0) * 3) AS engagement_score
FROM stats_ceb_sf1.users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
ORDER BY engagement_score DESC
LIMIT 10
