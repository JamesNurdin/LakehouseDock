WITH post_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        u_owner.reputation AS owner_reputation,
        u_editor.reputation AS editor_reputation,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(v.bounty_sum, 0) AS bounty_sum,
        COALESCE(c.comment_sum, 0) AS comment_sum,
        COALESCE(c.comment_score_sum, 0) AS comment_score_sum
    FROM posts p
    LEFT JOIN users u_owner ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor ON p.lasteditoruserid = u_editor.id
    LEFT JOIN (
        SELECT
            postid,
            COUNT(*) AS vote_count,
            SUM(bountyamount) AS bounty_sum
        FROM votes
        GROUP BY postid
    ) v ON v.postid = p.id
    LEFT JOIN (
        SELECT
            postid,
            COUNT(*) AS comment_sum,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY postid
    ) c ON c.postid = p.id
), aggregated AS (
    SELECT
        posttypeid,
        COUNT(*) AS total_posts,
        AVG(post_score) AS avg_post_score,
        SUM(viewcount) AS total_views,
        SUM(vote_count) AS total_votes,
        SUM(bounty_sum) AS total_bounty_amount,
        AVG(owner_reputation) AS avg_owner_reputation,
        AVG(editor_reputation) AS avg_editor_reputation,
        SUM(comment_score_sum) AS total_comment_score
    FROM post_stats
    GROUP BY posttypeid
)
SELECT
    posttypeid,
    total_posts,
    avg_post_score,
    total_views,
    total_votes,
    total_bounty_amount,
    avg_owner_reputation,
    avg_editor_reputation,
    total_comment_score,
    CASE WHEN total_views > 0 THEN total_votes * 1.0 / total_views ELSE NULL END AS votes_per_view,
    RANK() OVER (ORDER BY avg_post_score DESC) AS rank_by_avg_score
FROM aggregated
ORDER BY total_posts DESC
