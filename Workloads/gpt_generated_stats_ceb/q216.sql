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
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid,
               COUNT(*) AS vote_count,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
               SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_tag_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS postlink_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_history AS (
        SELECT userid,
               COUNT(*) AS posthistory_event_count
        FROM posthistory
        GROUP BY userid
    )
SELECT u.id,
       u.reputation,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(p.total_views, 0) AS total_views,
       COALESCE(p.total_answers, 0) AS total_answers,
       COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(p.total_favorites, 0) AS total_favorites,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(v.vote_count, 0) AS vote_count,
       COALESCE(v.upvote_count, 0) AS upvote_count,
       COALESCE(v.downvote_count, 0) AS downvote_count,
       COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(l.postlink_count, 0) AS postlink_count,
       COALESCE(h.posthistory_event_count, 0) AS posthistory_event_count
FROM users u
LEFT JOIN user_posts p      ON p.userid = u.id
LEFT JOIN user_comments c   ON c.userid = u.id
LEFT JOIN user_votes v      ON v.userid = u.id
LEFT JOIN user_badges b     ON b.userid = u.id
LEFT JOIN user_tag_counts t ON t.userid = u.id
LEFT JOIN user_postlinks l  ON l.userid = u.id
LEFT JOIN user_history h    ON h.userid = u.id
ORDER BY u.reputation DESC, badge_count DESC
LIMIT 10
