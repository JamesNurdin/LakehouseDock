WITH tag_post AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.score,
        p.viewcount,
        u.reputation AS owner_reputation
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN users u ON p.owneruserid = u.id
    WHERE p.posttypeid = 1
      AND t.count > 0
),
post_agg AS (
    SELECT
        tag_id,
        COUNT(DISTINCT post_id) AS post_count,
        SUM(score) AS total_score,
        AVG(viewcount) AS avg_viewcount,
        AVG(owner_reputation) AS avg_owner_reputation
    FROM tag_post
    GROUP BY tag_id
),
vote_agg AS (
    SELECT
        t.id AS tag_id,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN votes v ON v.postid = p.id
    WHERE p.posttypeid = 1
      AND t.count > 0
    GROUP BY t.id
),
link_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(*) AS total_links,
        COUNT(DISTINCT CASE WHEN pl.postid = p.id THEN pl.relatedpostid ELSE pl.postid END) AS distinct_related_posts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    JOIN postlinks pl ON (pl.postid = p.id OR pl.relatedpostid = p.id)
    WHERE p.posttypeid = 1
      AND t.count > 0
    GROUP BY t.id
)
SELECT
    p.tag_id,
    p.post_count,
    p.total_score,
    p.avg_viewcount,
    p.avg_owner_reputation,
    v.upvote_count,
    v.downvote_count,
    v.distinct_voter_count,
    l.total_links,
    l.distinct_related_posts,
    RANK() OVER (ORDER BY p.total_score DESC) AS score_rank
FROM post_agg p
LEFT JOIN vote_agg v ON p.tag_id = v.tag_id
LEFT JOIN link_agg l ON p.tag_id = l.tag_id
ORDER BY p.total_score DESC
LIMIT 100
