WITH owned_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS owned_post_count,
        COALESCE(SUM(score), 0) AS owned_score_sum
    FROM posts
    GROUP BY owneruserid
),
owned_tags AS (
    SELECT
        p.owneruserid,
        COALESCE(SUM(t.count), 0) AS owned_tag_total
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT
        lasteditoruserid,
        COUNT(*) AS edited_post_count
    FROM posts
    GROUP BY lasteditoruserid
),
votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(op.owned_post_count, 0) AS owned_post_count,
    COALESCE(op.owned_score_sum, 0) AS owned_score_sum,
    COALESCE(ot.owned_tag_total, 0) AS owned_tag_total,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvote_count, 0) AS upvote_count,
    COALESCE(vc.downvote_count, 0) AS downvote_count,
    COALESCE(ep.edited_post_count, 0) AS edited_post_count
FROM users u
LEFT JOIN owned_posts op ON u.id = op.owneruserid
LEFT JOIN owned_tags ot ON u.id = ot.owneruserid
LEFT JOIN edited_posts ep ON u.id = ep.lasteditoruserid
LEFT JOIN votes_cast vc ON u.id = vc.userid
ORDER BY u.reputation DESC, u.id
LIMIT 100
