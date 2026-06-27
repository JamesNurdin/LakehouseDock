WITH
    -- Posts owned by each user (total count and average score)
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    -- Comments authored by each user
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments
        FROM comments
        GROUP BY userid
    ),
    -- Votes cast by each user
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    -- Votes received on posts owned by each user
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Badges earned by each user
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    -- Edits performed by each user (posts where they were the last editor)
    user_edits AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS total_edits
        FROM posts
        GROUP BY lasteditoruserid
    ),
    -- Post‑history entries authored by each user (direct user actions)
    user_posthistory_own AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory_own
        FROM posthistory
        GROUP BY userid
    ),
    -- Tag usage aggregated for posts owned by each user
    user_tag_uses AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(t.count) AS total_tag_uses
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    -- Number of related‑post links originating from posts owned by each user
    user_related_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_related_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Post‑history entries that refer to posts owned by each user (indirect actions)
    user_posthistory_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_posthistory_on_owned
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ue.total_edits, 0) AS total_edits,
    COALESCE(upho.total_posthistory_own, 0) AS total_posthistory_own,
    COALESCE(uph.total_posthistory_on_owned, 0) AS total_posthistory_on_owned,
    COALESCE(ut.total_tag_uses, 0) AS total_tag_uses,
    COALESCE(rl.total_related_links, 0) AS total_related_links
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_posthistory_own upho ON upho.user_id = u.id
LEFT JOIN user_posthistory_on_owned_posts uph ON uph.user_id = u.id
LEFT JOIN user_tag_uses ut ON ut.user_id = u.id
LEFT JOIN user_related_links rl ON rl.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
