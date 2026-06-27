WITH
    user_badges AS (
        SELECT u.id AS user_id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_comments_made AS (
        SELECT u.id AS user_id,
               COUNT(c.id) AS comment_made_count,
               COALESCE(SUM(c.score), 0) AS comment_made_score_sum
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_posts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS post_score_sum,
               COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
               COALESCE(SUM(p.answercount), 0) AS post_answercount_sum,
               COALESCE(SUM(p.commentcount), 0) AS post_commentcount_sum,
               COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS votes_cast_count,
               COALESCE(SUM(v.bountyamount), 0) AS votes_cast_bounty_sum
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT u.id AS user_id,
               COUNT(v2.id) AS votes_received_count,
               COALESCE(SUM(v2.bountyamount), 0) AS votes_received_bounty_sum
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v2 ON v2.postid = p.id
        GROUP BY u.id
    ),
    user_comments_on_posts AS (
        SELECT u.id AS user_id,
               COALESCE(AVG(c2.score), 0) AS avg_comment_score_on_posts,
               COALESCE(SUM(c2.score), 0) AS total_comment_score_on_posts,
               COUNT(c2.id) AS comment_on_posts_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN comments c2 ON c2.postid = p.id
        GROUP BY u.id
    ),
    user_posthistory_edits AS (
        SELECT u.id AS user_id,
               COUNT(ph.id) AS posthistory_by_user_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_posthistory_linked_posts AS (
        SELECT u.id AS user_id,
               COUNT(ph2.id) AS posthistory_on_user_posts_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN posthistory ph2 ON ph2.posthistorytypeid = p.id
        GROUP BY u.id
    ),
    user_postlinks AS (
        SELECT u.id AS user_id,
               COUNT(pl.id) AS postlinks_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN postlinks pl ON pl.postid = p.id OR pl.relatedpostid = p.id
        GROUP BY u.id
    ),
    user_tags AS (
        SELECT u.id AS user_id,
               COUNT(t.id) AS tag_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cm.comment_made_score_sum, 0) AS comment_made_score_sum,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(p.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(p.post_commentcount_sum, 0) AS post_commentcount_sum,
    COALESCE(p.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.votes_cast_bounty_sum, 0) AS votes_cast_bounty_sum,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.votes_received_bounty_sum, 0) AS votes_received_bounty_sum,
    COALESCE(cp.avg_comment_score_on_posts, 0) AS avg_comment_score_on_posts,
    COALESCE(cp.total_comment_score_on_posts, 0) AS total_comment_score_on_posts,
    COALESCE(cp.comment_on_posts_count, 0) AS comment_on_posts_count,
    COALESCE(ph.posthistory_by_user_count, 0) AS posthistory_by_user_count,
    COALESCE(phu.posthistory_on_user_posts_count, 0) AS posthistory_on_user_posts_count,
    COALESCE(pl.postlinks_count, 0) AS postlinks_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    (
        COALESCE(p.post_score_sum, 0) +
        COALESCE(cm.comment_made_score_sum, 0) +
        COALESCE(vc.votes_cast_bounty_sum, 0) +
        COALESCE(vr.votes_received_bounty_sum, 0)
    ) AS activity_score
FROM users u
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_comments_on_posts cp ON cp.user_id = u.id
LEFT JOIN user_posthistory_edits ph ON ph.user_id = u.id
LEFT JOIN user_posthistory_linked_posts phu ON phu.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
ORDER BY u.reputation DESC, activity_score DESC
LIMIT 10
