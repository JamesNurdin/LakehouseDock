WITH
    user_info AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    badge_counts AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_counts AS (
        SELECT
            owneruserid,
            COUNT(*) AS owned_post_count,
            SUM(viewcount) AS total_viewcount,
            AVG(score) AS avg_post_score,
            SUM(favoritecount) AS total_favoritecount,
            SUM(answercount) AS total_answercount,
            SUM(commentcount) AS total_commentcount,
            SUM(score) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    post_edited_counts AS (
        SELECT
            lasteditoruserid,
            COUNT(*) AS edited_post_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    comment_counts AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_cast_counts AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM votes
        GROUP BY userid
    ),
    post_vote_received_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS vote_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_type_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(ph.id) AS posthistory_type_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ui.id AS user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.owned_post_count, 0) AS owned_post_count,
    COALESCE(pc.total_viewcount, 0) AS total_viewcount,
    COALESCE(pc.avg_post_score, 0) AS avg_post_score,
    COALESCE(pc.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(pc.total_answercount, 0) AS total_answercount,
    COALESCE(pc.total_commentcount, 0) AS total_commentcount,
    COALESCE(pc.total_post_score, 0) AS total_post_score,
    COALESCE(pec.edited_post_count, 0) AS edited_post_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(cc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vcc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vcc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vcc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(pvrc.vote_received_count, 0) AS vote_received_count,
    COALESCE(pvrc.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(pvrc.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(phtc.posthistory_type_count, 0) AS posthistory_type_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(plc.postlink_count, 0) AS postlink_count
FROM user_info ui
LEFT JOIN badge_counts bc ON bc.userid = ui.id
LEFT JOIN post_counts pc ON pc.owneruserid = ui.id
LEFT JOIN post_edited_counts pec ON pec.lasteditoruserid = ui.id
LEFT JOIN comment_counts cc ON cc.userid = ui.id
LEFT JOIN vote_cast_counts vcc ON vcc.userid = ui.id
LEFT JOIN post_vote_received_counts pvrc ON pvrc.userid = ui.id
LEFT JOIN posthistory_counts phc ON phc.userid = ui.id
LEFT JOIN posthistory_type_counts phtc ON phtc.userid = ui.id
LEFT JOIN tag_counts tc ON tc.userid = ui.id
LEFT JOIN postlink_counts plc ON plc.userid = ui.id
ORDER BY ui.reputation DESC
LIMIT 100
