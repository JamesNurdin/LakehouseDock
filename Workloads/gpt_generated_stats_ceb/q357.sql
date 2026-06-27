WITH user_badge_counts AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
comment_agg AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        COALESCE(SUM(v.votetypeid), 0) AS vote_type_sum,
        COUNT(DISTINCT v.userid) AS distinct_voters
    FROM votes v
    GROUP BY v.postid
),
posthistory_agg AS (
    SELECT
        ph.posthistorytypeid AS postid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
postlink_agg AS (
    SELECT
        pl.postid,
        COUNT(*) AS postlink_count,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM postlinks pl
    GROUP BY pl.postid
),
tag_agg AS (
    SELECT
        t.excerptpostid AS postid,
        COUNT(*) AS tag_count,
        MIN(t.id) AS tag_id,
        MIN(t.count) AS tag_usage_count
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    u_owner.reputation AS owner_reputation,
    ub_owner.badge_count AS owner_badge_count,
    u_editor.reputation AS editor_reputation,
    ub_editor.badge_count AS editor_badge_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(va.distinct_voters, 0) AS distinct_voters,
    COALESCE(pha.posthistory_count, 0) AS posthistory_count,
    COALESCE(pla.postlink_count, 0) AS postlink_count,
    COALESCE(pla.distinct_related_posts, 0) AS distinct_related_posts,
    COALESCE(ta.tag_id, NULL) AS tag_id,
    COALESCE(ta.tag_usage_count, NULL) AS tag_usage_count,
    COALESCE(ta.tag_count, 0) AS tag_count
FROM posts p
LEFT JOIN users u_owner ON p.owneruserid = u_owner.id
LEFT JOIN user_badge_counts ub_owner ON p.owneruserid = ub_owner.user_id
LEFT JOIN users u_editor ON p.lasteditoruserid = u_editor.id
LEFT JOIN user_badge_counts ub_editor ON p.lasteditoruserid = ub_editor.user_id
LEFT JOIN comment_agg ca ON p.id = ca.postid
LEFT JOIN vote_agg va ON p.id = va.postid
LEFT JOIN posthistory_agg pha ON p.id = pha.postid
LEFT JOIN postlink_agg pla ON p.id = pla.postid
LEFT JOIN tag_agg ta ON p.id = ta.postid
ORDER BY vote_count DESC
LIMIT 100
