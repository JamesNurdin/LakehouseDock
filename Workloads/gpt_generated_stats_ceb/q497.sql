WITH tag_posts AS (
    SELECT t.id AS tag_id,
           t.count AS tag_count,
           p.id AS post_id,
           p.score AS post_score,
           p.viewcount AS post_viewcount,
           p.answercount AS post_answercount,
           p.owneruserid AS owner_user_id
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
post_comments AS (
    SELECT c.postid,
           COUNT(*) AS comment_cnt
    FROM comments c
    GROUP BY c.postid
),
post_votes AS (
    SELECT v.postid,
           COUNT(*) AS vote_cnt,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes v
    GROUP BY v.postid
),
post_history_counts AS (
    SELECT ph.posthistorytypeid AS post_id,
           COUNT(*) AS posthistory_cnt
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_links_counts AS (
    SELECT pl.postid AS post_id,
           COUNT(*) AS postlink_cnt
    FROM postlinks pl
    GROUP BY pl.postid
),
user_reputation AS (
    SELECT u.id AS user_id,
           u.reputation
    FROM users u
),
user_badge_counts AS (
    SELECT u.id AS user_id,
           COUNT(*) AS badge_cnt
    FROM badges b
    JOIN users u ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    tp.tag_id,
    tp.tag_count,
    COUNT(DISTINCT tp.post_id) AS post_cnt,
    SUM(tp.post_score) AS total_post_score,
    SUM(tp.post_viewcount) AS total_viewcount,
    SUM(tp.post_answercount) AS total_answercount,
    COALESCE(SUM(pc.comment_cnt), 0) AS total_comment_cnt,
    COALESCE(SUM(pv.vote_cnt), 0) AS total_vote_cnt,
    COALESCE(SUM(pv.upvote_cnt), 0) AS total_upvote_cnt,
    COALESCE(SUM(pv.downvote_cnt), 0) AS total_downvote_cnt,
    COALESCE(SUM(phc.posthistory_cnt), 0) AS total_posthistory_cnt,
    COALESCE(SUM(plc.postlink_cnt), 0) AS total_postlink_cnt,
    AVG(ur.reputation) AS avg_owner_reputation,
    COALESCE(SUM(ubc.badge_cnt), 0) AS total_owner_badge_cnt
FROM tag_posts tp
LEFT JOIN post_comments pc ON tp.post_id = pc.postid
LEFT JOIN post_votes pv ON tp.post_id = pv.postid
LEFT JOIN post_history_counts phc ON tp.post_id = phc.post_id
LEFT JOIN post_links_counts plc ON tp.post_id = plc.post_id
LEFT JOIN user_reputation ur ON tp.owner_user_id = ur.user_id
LEFT JOIN user_badge_counts ubc ON tp.owner_user_id = ubc.user_id
GROUP BY tp.tag_id, tp.tag_count
ORDER BY post_cnt DESC
LIMIT 10
