WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
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
               AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid,
               COUNT(*) AS vote_count,
               COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS upvote_cast,
               COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS downvote_cast
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_tag_excerpts AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_history AS (
        SELECT userid,
               COUNT(*) AS history_event_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(uh.history_event_count, 0) AS history_event_count,
    COALESCE(up_links.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_tag_excerpts ut ON ut.userid = u.id
LEFT JOIN user_history uh ON uh.userid = u.id
LEFT JOIN user_postlinks up_links ON up_links.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
