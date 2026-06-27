WITH post_base AS (
    SELECT id,
           posttypeid,
           creationdate,
           score,
           viewcount,
           owneruserid,
           answercount,
           commentcount,
           favoritecount,
           lasteditoruserid
    FROM posts
),
vote_agg AS (
    SELECT postid,
           COUNT(*) AS vote_count,
           SUM(votetypeid) AS vote_type_sum,
           COALESCE(SUM(bountyamount), 0) AS total_bounty
    FROM votes
    GROUP BY postid
),
comment_agg AS (
    SELECT postid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
postlink_agg AS (
    SELECT postid,
           COUNT(*) AS outgoing_link_count,
           SUM(CASE WHEN linktypeid = 1 THEN 1 ELSE 0 END) AS link_type1_count
    FROM postlinks
    GROUP BY postid
)
SELECT
    date_trunc('month', p.creationdate) AS month_start,
    p.posttypeid,
    COUNT(*) AS post_count,
    SUM(p.score) AS total_post_score,
    AVG(p.score) AS avg_post_score,
    SUM(p.viewcount) AS total_view_count,
    AVG(p.viewcount) AS avg_view_count,
    SUM(p.answercount) AS total_answer_count,
    AVG(p.answercount) AS avg_answer_count,
    SUM(p.commentcount) AS total_comment_count,
    AVG(p.commentcount) AS avg_comment_count,
    SUM(COALESCE(v.vote_count, 0)) AS total_vote_count,
    SUM(COALESCE(v.vote_type_sum, 0)) AS total_vote_type_sum,
    SUM(COALESCE(v.total_bounty, 0)) AS total_bounty_amount,
    SUM(COALESCE(c.comment_count, 0)) AS total_comment_agg_count,
    SUM(COALESCE(c.comment_score_sum, 0)) AS total_comment_agg_score,
    SUM(COALESCE(pl.outgoing_link_count, 0)) AS total_outgoing_links,
    SUM(COALESCE(pl.link_type1_count, 0)) AS total_link_type1,
    COUNT(DISTINCT p.owneruserid) AS distinct_owner_users,
    AVG(u.reputation) AS avg_owner_reputation,
    SUM(u.reputation) AS total_owner_reputation,
    COUNT(DISTINCT t.id) AS distinct_tag_excerpts
FROM post_base p
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN postlink_agg pl ON pl.postid = p.id
LEFT JOIN users u ON u.id = p.owneruserid
LEFT JOIN tags t ON t.excerptpostid = p.id
GROUP BY
    date_trunc('month', p.creationdate),
    p.posttypeid
ORDER BY month_start DESC, p.posttypeid
