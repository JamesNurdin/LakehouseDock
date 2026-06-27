WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_views,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments_on_posts,
           SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
           SUM(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_edits AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_last_edits AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS last_edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_outgoing_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS outgoing_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_incoming_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS incoming_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(up.total_answers, 0) AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_cast, 0) AS upvote_cast,
       COALESCE(uv.downvote_cast, 0) AS downvote_cast,
       COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(ue.posthistory_count, 0) AS posthistory_count,
       COALESCE(ul.last_edit_count, 0) AS last_edit_count,
       COALESCE(uol.outgoing_link_count, 0) AS outgoing_link_count,
       COALESCE(uil.incoming_link_count, 0) AS incoming_link_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_votes uv ON u.id = uv.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_last_edits ul ON u.id = ul.userid
LEFT JOIN user_outgoing_links uol ON u.id = uol.userid
LEFT JOIN user_incoming_links uil ON u.id = uil.userid
ORDER BY u.reputation DESC
LIMIT 100
