WITH
    user_posts_agg AS (
        SELECT u.id,
               COUNT(p.id) AS total_posts_owned,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_post_viewcount
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments_agg AS (
        SELECT u.id,
               COUNT(c.id) AS total_comments_made,
               COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast_agg AS (
        SELECT u.id,
               COUNT(v.id) AS total_votes_cast,
               COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received_agg AS (
        SELECT u.id,
               COUNT(v.id) AS total_votes_received,
               COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges_agg AS (
        SELECT u.id,
               COUNT(b.id) AS total_badges_earned
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_tags_agg AS (
        SELECT u.id,
               COUNT(DISTINCT t.id) AS distinct_tags_on_owned_posts,
               COALESCE(SUM(t.count), 0) AS total_tag_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.total_posts_owned, 0) AS total_posts_owned,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_post_viewcount, 0) AS total_post_viewcount,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(b.total_badges_earned, 0) AS total_badges_earned,
    COALESCE(t.distinct_tags_on_owned_posts, 0) AS distinct_tags_on_owned_posts,
    COALESCE(t.total_tag_count, 0) AS total_tag_count
FROM users u
LEFT JOIN user_posts_agg up ON up.id = u.id
LEFT JOIN user_comments_agg uc ON uc.id = u.id
LEFT JOIN user_votes_cast_agg vc ON vc.id = u.id
LEFT JOIN user_votes_received_agg vr ON vr.id = u.id
LEFT JOIN user_badges_agg b ON b.id = u.id
LEFT JOIN user_tags_agg t ON t.id = u.id
ORDER BY total_posts_owned DESC
LIMIT 100
