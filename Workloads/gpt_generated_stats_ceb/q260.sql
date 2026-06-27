WITH
    posts_by_user AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_posts_score,
            SUM(answercount) AS total_answers,
            SUM(favoritecount) AS total_favorite,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    comments_made AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_made
        FROM comments
        GROUP BY userid
    ),
    comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_comments_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_earned AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges,
            MIN(date) AS first_badge_date,
            MAX(date) AS last_badge_date
        FROM badges
        GROUP BY userid
    ),
    tags_created AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_tags_created
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_owned AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_postlinks
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_related AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_related_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory_by_user
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_on_user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_posthistory_on_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(pbu.total_posts, 0) AS total_posts,
    COALESCE(pbu.total_posts_score, 0) AS total_posts_score,
    COALESCE(pbu.total_answers, 0) AS total_answers,
    COALESCE(pbu.total_favorite, 0) AS total_favorite,
    COALESCE(pbu.total_views, 0) AS total_post_views,
    COALESCE(cm.total_comments_made, 0) AS total_comments_made,
    COALESCE(cr.total_comments_received, 0) AS total_comments_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(vc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.up_votes_received, 0) AS up_votes_received,
    COALESCE(vr.down_votes_received, 0) AS down_votes_received,
    COALESCE(be.total_badges, 0) AS total_badges,
    be.first_badge_date,
    be.last_badge_date,
    COALESCE(tc.total_tags_created, 0) AS total_tags_created,
    COALESCE(pl_own.total_postlinks, 0) AS total_postlinks_owned,
    COALESCE(pl_rel.total_related_links, 0) AS total_related_links,
    COALESCE(ph_user.total_posthistory_by_user, 0) AS total_posthistory_by_user,
    COALESCE(ph_posts.total_posthistory_on_posts, 0) AS total_posthistory_on_posts
FROM users u
LEFT JOIN posts_by_user pbu ON u.id = pbu.user_id
LEFT JOIN comments_made cm ON u.id = cm.user_id
LEFT JOIN comments_received cr ON u.id = cr.user_id
LEFT JOIN votes_cast vc ON u.id = vc.user_id
LEFT JOIN votes_received vr ON u.id = vr.user_id
LEFT JOIN badges_earned be ON u.id = be.user_id
LEFT JOIN tags_created tc ON u.id = tc.user_id
LEFT JOIN postlinks_owned pl_own ON u.id = pl_own.user_id
LEFT JOIN postlinks_related pl_rel ON u.id = pl_rel.user_id
LEFT JOIN posthistory_by_user ph_user ON u.id = ph_user.user_id
LEFT JOIN posthistory_on_user_posts ph_posts ON u.id = ph_posts.user_id
ORDER BY u.reputation DESC
LIMIT 100
