WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_stats AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_views,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments,
           SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
tag_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
link_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS postlink_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.total_post_score, 0) AS total_post_score,
       COALESCE(ps.total_views, 0) AS total_views,
       COALESCE(ps.total_answers, 0) AS total_answers,
       COALESCE(ps.total_comments, 0) AS total_comments,
       COALESCE(ps.total_favorites, 0) AS total_favorites,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.total_comment_score, 0) AS total_comment_score,
       COALESCE(vs.vote_count, 0) AS vote_count,
       COALESCE(vs.upvote_count, 0) AS upvote_count,
       COALESCE(vs.downvote_count, 0) AS downvote_count,
       COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(lc.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_stats ps ON ps.userid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
LEFT JOIN tag_counts tc ON tc.userid = u.id
LEFT JOIN link_counts lc ON lc.userid = u.id
ORDER BY badge_count DESC, u.reputation DESC
LIMIT 50
