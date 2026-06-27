WITH
    user_base AS (
        SELECT id,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS post_score_sum,
               AVG(score) AS post_score_avg,
               SUM(viewcount) AS post_view_sum,
               SUM(answercount) AS answer_total,
               SUM(commentcount) AS comment_total,
               SUM(favoritecount) AS favorite_total
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               AVG(score) AS comment_score_avg
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received_count,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
               SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory_edits AS (
        SELECT userid,
               COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks_created AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags_on_posts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.answer_total, 0) AS answer_total,
    COALESCE(up.comment_total, 0) AS comment_total,
    COALESCE(up.favorite_total, 0) AS favorite_total,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.edit_count, 0) AS edit_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(tg.tag_count, 0) AS tag_count
FROM user_base u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_posthistory_edits ph ON ph.userid = u.id
LEFT JOIN user_postlinks_created pl ON pl.userid = u.id
LEFT JOIN user_tags_on_posts tg ON tg.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
