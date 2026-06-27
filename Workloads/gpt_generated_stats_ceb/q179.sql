WITH user_info AS (
    SELECT id,
           reputation,
           creationdate,
           views,
           upvotes,
           downvotes
    FROM users
),
badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_stats AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score_sum,
           SUM(viewcount) AS post_view_sum,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments_on_posts,
           SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
vote_cast_stats AS (
    SELECT userid,
           COUNT(*) AS vote_cast_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes
    GROUP BY userid
),
vote_received_stats AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS vote_received_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
posthistory_stats AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
postlink_stats AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id) AS postlink_count,
           COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
tag_stats AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id) AS tag_excerpt_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.post_score_sum, 0) AS post_score_sum,
       COALESCE(p.post_view_sum, 0) AS post_view_sum,
       COALESCE(p.total_answers, 0) AS total_answers,
       COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(p.total_favorites, 0) AS total_favorites,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(vc.upvote_cast, 0) AS upvote_cast,
       COALESCE(vc.downvote_cast, 0) AS downvote_cast,
       COALESCE(vr.vote_received_count, 0) AS vote_received_count,
       COALESCE(vr.upvote_received, 0) AS upvote_received,
       COALESCE(vr.downvote_received, 0) AS downvote_received,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count,
       COALESCE(pl.postlink_count, 0) AS postlink_count,
       COALESCE(pl.distinct_related_posts, 0) AS distinct_related_posts,
       COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count
FROM user_info u
LEFT JOIN badge_counts b ON b.userid = u.id
LEFT JOIN post_stats p ON p.userid = u.id
LEFT JOIN comment_stats c ON c.userid = u.id
LEFT JOIN vote_cast_stats vc ON vc.userid = u.id
LEFT JOIN vote_received_stats vr ON vr.userid = u.id
LEFT JOIN posthistory_stats ph ON ph.userid = u.id
LEFT JOIN postlink_stats pl ON pl.userid = u.id
LEFT JOIN tag_stats t ON t.userid = u.id
WHERE u.reputation > 1000
ORDER BY post_score_sum DESC
LIMIT 100
