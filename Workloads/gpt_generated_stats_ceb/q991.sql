/*
  Monthly analytics for the Stack Exchange data set.
  The query aggregates posts, comments, votes, tags, badges, and owner reputation
  per month (truncated to the month) and per post type.  It also breaks down votes
  by vote type and ranks post types by the number of posts created each month.
*/
WITH post_agg AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        p.posttypeid,
        COUNT(*) AS post_cnt,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg,
        COUNT(DISTINCT p.owneruserid) AS distinct_owners,
        COUNT(DISTINCT p.lasteditoruserid) AS distinct_editors
    FROM posts p
    GROUP BY date_trunc('month', p.creationdate), p.posttypeid
),
comment_agg AS (
    SELECT
        date_trunc('month', c.creationdate) AS month,
        COUNT(*) AS comment_cnt,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    GROUP BY date_trunc('month', c.creationdate)
),
vote_agg AS (
    SELECT
        date_trunc('month', v.creationdate) AS month,
        v.votetypeid,
        COUNT(*) AS vote_cnt,
        SUM(v.bountyamount) AS total_bounty_amount,
        COUNT(DISTINCT v.userid) AS distinct_voters
    FROM votes v
    GROUP BY date_trunc('month', v.creationdate), v.votetypeid
),
tag_agg AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        COUNT(DISTINCT t.id) AS distinct_tags_used
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY date_trunc('month', p.creationdate)
),
badge_agg AS (
    SELECT
        date_trunc('month', b.date) AS month,
        COUNT(*) AS badge_cnt,
        COUNT(DISTINCT b.userid) AS distinct_badge_earners
    FROM badges b
    GROUP BY date_trunc('month', b.date)
),
owner_rep_agg AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        AVG(u.reputation) AS avg_owner_reputation,
        COUNT(DISTINCT p.owneruserid) AS owner_user_cnt
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    GROUP BY date_trunc('month', p.creationdate)
)
SELECT
    p.month,
    p.posttypeid,
    p.post_cnt,
    p.post_score_sum,
    p.post_score_avg,
    p.distinct_owners,
    p.distinct_editors,
    COALESCE(c.comment_cnt, 0) AS comment_cnt,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(c.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(c.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(v.vote_cnt, 0) AS vote_cnt,
    v.votetypeid,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(v.distinct_voters, 0) AS distinct_voters,
    COALESCE(t.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(b.badge_cnt, 0) AS badge_cnt,
    COALESCE(b.distinct_badge_earners, 0) AS distinct_badge_earners,
    COALESCE(o.avg_owner_reputation, 0) AS avg_owner_reputation,
    COALESCE(o.owner_user_cnt, 0) AS owner_user_cnt,
    ROW_NUMBER() OVER (PARTITION BY p.month ORDER BY p.post_cnt DESC) AS posttype_rank
FROM post_agg p
LEFT JOIN comment_agg c ON c.month = p.month
LEFT JOIN vote_agg v ON v.month = p.month
LEFT JOIN tag_agg t ON t.month = p.month
LEFT JOIN badge_agg b ON b.month = p.month
LEFT JOIN owner_rep_agg o ON o.month = p.month
ORDER BY p.month DESC, p.posttypeid
