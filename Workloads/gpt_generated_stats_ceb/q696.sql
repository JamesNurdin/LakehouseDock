WITH post_base AS (
    SELECT
        p.id AS post_id,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        DATE_TRUNC('month', p.creationdate) AS month_dt
    FROM posts p
),
owner_rep AS (
    SELECT u.id AS user_id, u.reputation
    FROM users u
),
editor_rep AS (
    SELECT u.id AS user_id, u.reputation
    FROM users u
),
comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_cnt,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.postid
),
comment_user_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(DISTINCT c.userid) AS distinct_commenters,
        AVG(u.reputation) AS avg_commenter_rep,
        SUM(u.reputation) AS sum_commenter_rep
    FROM comments c
    JOIN users u ON u.id = c.userid
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(v.bountyamount) AS bounty_sum
    FROM votes v
    GROUP BY v.postid
),
tag_agg AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_cnt,
        SUM(t.count) AS tag_use_sum
    FROM tags t
    GROUP BY t.excerptpostid
),
posthistory_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS history_cnt,
        MIN(ph.creationdate) AS first_history_dt,
        MAX(ph.creationdate) AS last_history_dt
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    pb.month_dt,
    COUNT(DISTINCT pb.post_id) AS posts_in_month,
    AVG(pb.post_score) AS avg_post_score,
    AVG(pb.viewcount) AS avg_viewcount,
    AVG(pb.answercount) AS avg_answercount,
    AVG(pb.commentcount) AS avg_commentcount,
    AVG(pb.favoritecount) AS avg_favoritecount,
    COALESCE(SUM(ca.comment_cnt), 0) AS total_comments,
    COALESCE(SUM(ca.comment_score_sum), 0) AS total_comment_score,
    COALESCE(SUM(va.vote_cnt), 0) AS total_votes,
    COALESCE(SUM(va.upvote_cnt), 0) AS total_upvotes,
    COALESCE(SUM(va.downvote_cnt), 0) AS total_downvotes,
    COALESCE(SUM(va.bounty_sum), 0) AS total_bounty_amount,
    COALESCE(SUM(ta.tag_cnt), 0) AS total_tags,
    COALESCE(SUM(ta.tag_use_sum), 0) AS total_tag_use,
    COALESCE(SUM(ph.history_cnt), 0) AS total_posthistory_events,
    AVG(or_user.reputation) AS avg_owner_reputation,
    AVG(er_user.reputation) AS avg_last_editor_reputation,
    COALESCE(SUM(cau.distinct_commenters), 0) AS total_distinct_commenters,
    AVG(cau.avg_commenter_rep) AS avg_commenter_reputation
FROM post_base pb
LEFT JOIN comment_agg ca ON ca.post_id = pb.post_id
LEFT JOIN comment_user_agg cau ON cau.post_id = pb.post_id
LEFT JOIN vote_agg va ON va.post_id = pb.post_id
LEFT JOIN tag_agg ta ON ta.post_id = pb.post_id
LEFT JOIN posthistory_agg ph ON ph.post_id = pb.post_id
LEFT JOIN owner_rep or_user ON or_user.user_id = pb.owneruserid
LEFT JOIN editor_rep er_user ON er_user.user_id = pb.lasteditoruserid
GROUP BY pb.month_dt
ORDER BY pb.month_dt
