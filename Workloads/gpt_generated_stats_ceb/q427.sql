WITH
    owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS owned_posts,
            COALESCE(SUM(p.score), 0) AS owned_posts_score
        FROM posts p
        GROUP BY p.owneruserid
    ),
    edited_posts AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edited_posts,
            COALESCE(SUM(p.score), 0) AS edited_posts_score
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    comments_made AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            COALESCE(SUM(c.score), 0) AS comments_score
        FROM comments c
        GROUP BY c.userid
    ),
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
        FROM votes v
        GROUP BY v.userid
    ),
    badges_earned AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_entries AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_entries
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    tag_excerpts_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpts_on_owned_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(op.owned_posts, 0) AS owned_posts,
    COALESCE(op.owned_posts_score, 0) AS owned_posts_score,
    COALESCE(ep.edited_posts, 0) AS edited_posts,
    COALESCE(ep.edited_posts_score, 0) AS edited_posts_score,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.comments_score, 0) AS comments_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(be.badges_earned, 0) AS badges_earned,
    COALESCE(ph.posthistory_entries, 0) AS posthistory_entries,
    COALESCE(te.tag_excerpts_on_owned_posts, 0) AS tag_excerpts_on_owned_posts
FROM users u
LEFT JOIN owned_posts op ON u.id = op.user_id
LEFT JOIN edited_posts ep ON u.id = ep.user_id
LEFT JOIN comments_made cm ON u.id = cm.user_id
LEFT JOIN votes_cast vc ON u.id = vc.user_id
LEFT JOIN badges_earned be ON u.id = be.user_id
LEFT JOIN posthistory_entries ph ON u.id = ph.user_id
LEFT JOIN tag_excerpts_on_owned_posts te ON u.id = te.user_id
ORDER BY owned_posts_score DESC
LIMIT 100
