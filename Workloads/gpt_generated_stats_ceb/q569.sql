WITH user_posts AS (
    SELECT 
        owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT 
        userid AS user_id,
        COUNT(*) AS total_comments_made,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT 
        userid AS user_id,
        COUNT(*) AS total_votes_cast,
        SUM(bountyamount) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
post_votes_received AS (
    SELECT 
        p.owneruserid AS user_id,
        COUNT(v.id) AS total_votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT 
        userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
user_tag_excerpts AS (
    SELECT 
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS total_tags_excerpt_for_user_posts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT 
        userid AS user_id,
        COUNT(*) AS total_edits_made
    FROM posthistory
    GROUP BY userid
),
user_post_links AS (
    SELECT 
        p.owneruserid AS user_id,
        COUNT(pl.id) AS total_post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT 
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(pvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ute.total_tags_excerpt_for_user_posts, 0) AS total_tags_excerpt_for_user_posts,
    COALESCE(ue.total_edits_made, 0) AS total_edits_made,
    COALESCE(upl.total_post_links, 0) AS total_post_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN post_votes_received pvr ON pvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_post_links upl ON upl.user_id = u.id
ORDER BY total_posts DESC, total_answers DESC
LIMIT 100
