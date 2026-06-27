WITH
user_posts AS (
    SELECT
        users.id AS user_id,
        COUNT(posts.id) AS total_posts,
        SUM(posts.score) AS total_post_score,
        AVG(posts.score) AS avg_post_score,
        SUM(posts.answercount) AS total_answer_count,
        SUM(posts.commentcount) AS total_comment_count,
        SUM(posts.favoritecount) AS total_favorite_count,
        SUM(posts.viewcount) AS total_view_count
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    GROUP BY users.id
),
user_comments_made AS (
    SELECT
        users.id AS user_id,
        COUNT(comments.id) AS total_comments_made
    FROM users
    LEFT JOIN comments ON comments.userid = users.id
    GROUP BY users.id
),
user_comments_received AS (
    SELECT
        users.id AS user_id,
        COUNT(comments.id) AS total_comments_received
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN comments ON comments.postid = posts.id
    GROUP BY users.id
),
user_votes_cast AS (
    SELECT
        users.id AS user_id,
        COUNT(votes.id) AS total_votes_cast,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY users.id
),
user_votes_received AS (
    SELECT
        users.id AS user_id,
        COUNT(votes.id) AS total_votes_received,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN votes ON votes.postid = posts.id
    GROUP BY users.id
),
user_badges AS (
    SELECT
        users.id AS user_id,
        COUNT(badges.id) AS total_badges
    FROM users
    LEFT JOIN badges ON badges.userid = users.id
    GROUP BY users.id
),
user_tags AS (
    SELECT
        users.id AS user_id,
        COUNT(tags.id) AS total_tags_excerpts
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN tags ON tags.excerptpostid = posts.id
    GROUP BY users.id
),
user_posthistory AS (
    SELECT
        users.id AS user_id,
        COUNT(posthistory.id) AS total_posthistory_events
    FROM users
    LEFT JOIN posthistory ON posthistory.userid = users.id
    GROUP BY users.id
),
user_postlinks_outgoing AS (
    SELECT
        users.id AS user_id,
        COUNT(postlinks.id) AS total_outgoing_links
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN postlinks ON postlinks.postid = posts.id
    GROUP BY users.id
),
user_postlinks_incoming AS (
    SELECT
        users.id AS user_id,
        COUNT(postlinks.id) AS total_incoming_links
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN postlinks ON postlinks.relatedpostid = posts.id
    GROUP BY users.id
)

SELECT
    u.id AS user_id,
    u.reputation AS reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(cm.total_comments_made, 0) AS total_comments_made,
    COALESCE(cr.total_comments_received, 0) AS total_comments_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(t.total_tags_excerpts, 0) AS total_tags_excerpts,
    COALESCE(ph.total_posthistory_events, 0) AS total_posthistory_events,
    COALESCE(pl_out.total_outgoing_links, 0) AS total_outgoing_links,
    COALESCE(pl_in.total_incoming_links, 0) AS total_incoming_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_received cr ON cr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_tags t ON t.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_postlinks_outgoing pl_out ON pl_out.user_id = u.id
LEFT JOIN user_postlinks_incoming pl_in ON pl_in.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
