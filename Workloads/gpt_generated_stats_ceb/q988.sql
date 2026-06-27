WITH posts_agg AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS view_sum
    FROM posts
    GROUP BY owneruserid
),
comments_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
votes_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY userid
),
badges_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
history_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY userid
),
self_edit_agg AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS self_edit_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    WHERE p.owneruserid = ph.userid
    GROUP BY ph.userid
),
outbound_links_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS outbound_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
inbound_links_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS inbound_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.post_score_sum, 0) AS post_score_sum,
    COALESCE(pa.view_sum, 0) AS view_sum,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(ba.badge_count, 0) AS badge_count,
    COALESCE(ha.history_count, 0) AS history_count,
    COALESCE(sea.self_edit_count, 0) AS self_edit_count,
    COALESCE(ola.outbound_link_count, 0) AS outbound_link_count,
    COALESCE(ila.inbound_link_count, 0) AS inbound_link_count,
    (u.reputation
        + COALESCE(pa.post_score_sum, 0)
        + COALESCE(ca.comment_count, 0) * 2
        + COALESCE(va.vote_count, 0) * 3) AS activity_score
FROM users u
LEFT JOIN posts_agg pa ON u.id = pa.user_id
LEFT JOIN comments_agg ca ON u.id = ca.user_id
LEFT JOIN votes_agg va ON u.id = va.user_id
LEFT JOIN badges_agg ba ON u.id = ba.user_id
LEFT JOIN history_agg ha ON u.id = ha.user_id
LEFT JOIN self_edit_agg sea ON u.id = sea.user_id
LEFT JOIN outbound_links_agg ola ON u.id = ola.user_id
LEFT JOIN inbound_links_agg ila ON u.id = ila.user_id
ORDER BY activity_score DESC
LIMIT 10
