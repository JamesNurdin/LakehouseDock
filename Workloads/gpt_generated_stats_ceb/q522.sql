WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_post_views,
        COALESCE(SUM(answercount), 0) AS total_answer_count,
        COALESCE(SUM(commentcount), 0) AS total_comment_count_on_posts,
        COALESCE(SUM(favoritecount), 0) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_posts_edited
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_outgoing_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS outgoing_links,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_incoming_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS incoming_links,
        COUNT(DISTINCT pl.postid) AS distinct_source_posts
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count_on_posts, 0) AS total_comment_count_on_posts,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ue.distinct_posts_edited, 0) AS distinct_posts_edited,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uol.outgoing_links, 0) AS outgoing_links,
    COALESCE(uol.distinct_related_posts, 0) AS distinct_related_posts,
    COALESCE(uil.incoming_links, 0) AS incoming_links,
    COALESCE(uil.distinct_source_posts, 0) AS distinct_source_posts
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes_cast uvc ON u.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_edits ue ON u.id = ue.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
LEFT JOIN user_outgoing_links uol ON u.id = uol.user_id
LEFT JOIN user_incoming_links uil ON u.id = uil.user_id
ORDER BY u.reputation DESC
LIMIT 100
