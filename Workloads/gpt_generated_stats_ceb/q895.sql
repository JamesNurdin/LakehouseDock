WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score
    FROM comments c
    GROUP BY c.userid
),
user_comments_on_own_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS comment_on_own_posts_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
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
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags_used AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tags_used
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_owned AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlinks_owned
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
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score, 0) AS comment_score,
    COALESCE(uco.comment_on_own_posts_count, 0) AS comment_on_own_posts_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tu.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(pl.postlinks_owned, 0) AS postlinks_owned
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_comments_on_own_posts uco ON uco.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
LEFT JOIN user_tags_used tu ON tu.userid = u.id
LEFT JOIN user_postlinks_owned pl ON pl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
