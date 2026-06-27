-- Analytical query: summary of user activity across posts, comments, votes, badges, post‑history and tags
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.viewcount), 0) AS avg_view_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id                 -- posts.owneruserid = users.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id                     -- comments.userid = users.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id                     -- votes.userid = users.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id                     -- badges.userid = users.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id                     -- posthistory.userid = users.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id          -- posthistory.posthistorytypeid = posts.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id                 -- posts.owneruserid = users.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id                -- tags.excerptpostid = posts.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_view_count,
    up.total_favorite_count,
    uc.comment_count,
    uc.total_comment_score,
    uv.vote_count,
    uv.upvote_count,
    uv.downvote_count,
    uv.total_bounty_amount,
    ub.badge_count,
    uph.posthistory_count,
    ut.tag_count
FROM user_posts up
LEFT JOIN user_comments uc      ON uc.user_id = up.user_id
LEFT JOIN user_votes uv         ON uv.user_id = up.user_id
LEFT JOIN user_badges ub        ON ub.user_id = up.user_id
LEFT JOIN user_posthistory uph  ON uph.user_id = up.user_id
LEFT JOIN user_tags ut          ON ut.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 100
