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
    badges_agg AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posts_owned_agg AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_owned_count,
            SUM(score) AS post_owned_score_sum,
            SUM(viewcount) AS post_owned_view_sum,
            SUM(answercount) AS post_owned_answer_sum,
            SUM(commentcount) AS post_owned_comment_sum,
            SUM(favoritecount) AS post_owned_favorite_sum
        FROM posts
        GROUP BY owneruserid
    ),
    posts_edited_agg AS (
        SELECT
            lasteditoruserid,
            COUNT(*) AS post_edited_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comments_agg AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    votes_cast_agg AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count,
            SUM(v.bountyamount) AS bounty_received_sum
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_agg AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p_o.post_owned_count, 0) AS post_owned_count,
    COALESCE(p_o.post_owned_score_sum, 0) AS post_owned_score_sum,
    COALESCE(p_o.post_owned_view_sum, 0) AS post_owned_view_sum,
    COALESCE(p_o.post_owned_answer_sum, 0) AS post_owned_answer_sum,
    COALESCE(p_o.post_owned_comment_sum, 0) AS post_owned_comment_sum,
    COALESCE(p_o.post_owned_favorite_sum, 0) AS post_owned_favorite_sum,
    COALESCE(p_e.post_edited_count, 0) AS post_edited_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v_c.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(v_c.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(v_c.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(v_r.votes_received_count, 0) AS votes_received_count,
    COALESCE(v_r.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(v_r.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(v_r.bounty_received_sum, 0) AS bounty_received_sum,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM user_info u
LEFT JOIN badges_agg b
    ON u.id = b.userid
LEFT JOIN posts_owned_agg p_o
    ON u.id = p_o.owneruserid
LEFT JOIN posts_edited_agg p_e
    ON u.id = p_e.lasteditoruserid
LEFT JOIN comments_agg c
    ON u.id = c.userid
LEFT JOIN votes_cast_agg v_c
    ON u.id = v_c.userid
LEFT JOIN votes_received_agg v_r
    ON u.id = v_r.owneruserid
LEFT JOIN posthistory_agg ph
    ON u.id = ph.userid
ORDER BY u.reputation DESC
LIMIT 10
