/*
  Analytical query: user activity summary across posts, comments, votes, badges, tags, and post links.
  Shows reputation, counts, sums and averages for users with reputation > 1000.
*/
WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(score) AS total_post_score,
        AVG(viewcount) AS avg_post_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS total_edits
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_comments,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_votes,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS total_posthistory
    FROM posthistory
    GROUP BY userid
),
user_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT pl.id) AS total_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
    UNION ALL
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT pl.id) AS total_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_links_agg AS (
    SELECT
        user_id,
        SUM(total_links) AS total_links
    FROM user_links
    GROUP BY user_id
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        SUM(t."count") AS total_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts_authored,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_viewcount, 0) AS avg_post_viewcount,
    COALESCE(ue.total_edits, 0) AS total_posts_edited,
    COALESCE(uc.total_comments, 0) AS total_comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.total_votes, 0) AS total_votes_cast,
    COALESCE(uv.total_bounty, 0) AS total_bounty_amount,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(uph.total_posthistory, 0) AS total_posthistory,
    COALESCE(ul.total_links, 0) AS total_linked_posts,
    COALESCE(ut.total_tag_count, 0) AS total_tag_count_on_posts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_links_agg ul ON ul.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
WHERE u.reputation > 1000
ORDER BY total_posts_authored DESC
LIMIT 100
