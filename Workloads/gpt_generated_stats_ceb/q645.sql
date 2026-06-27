WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(SUM(p.viewcount), 0) AS view_sum,
            COALESCE(SUM(p.answercount), 0) AS answer_sum,
            COALESCE(SUM(p.commentcount), 0) AS comment_count_sum,
            COALESCE(SUM(p.favoritecount), 0) AS favorite_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS userid,
            COUNT(*) AS votes_cast,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS distinct_tag_count,
            COALESCE(SUM(t.count), 0) AS tag_usage_sum
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS userid,
            COUNT(*) AS posthistory_event_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY ph.userid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.view_sum, 0) AS view_sum,
    COALESCE(up.answer_sum, 0) AS answer_sum,
    COALESCE(up.comment_count_sum, 0) AS post_comment_count_sum,
    COALESCE(up.favorite_sum, 0) AS favorite_sum,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(t.tag_usage_sum, 0) AS tag_usage_sum,
    COALESCE(ph.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_tags t ON t.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
LEFT JOIN user_postlinks pl ON pl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
