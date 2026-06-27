WITH vote_agg AS (
    SELECT
        votes.postid AS post_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(COALESCE(votes.bountyamount, 0)) AS total_bounty
    FROM votes
    GROUP BY votes.postid
),
history_agg AS (
    SELECT
        posthistory.posthistorytypeid AS post_id,
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistory.posthistorytypeid
),
link_agg AS (
    SELECT
        postlinks.postid AS post_id,
        COUNT(*) AS outgoing_link_count,
        SUM(CASE WHEN postlinks.linktypeid = 1 THEN 1 ELSE 0 END) AS duplicate_link_count
    FROM postlinks
    GROUP BY postlinks.postid
),
related_link_agg AS (
    SELECT
        postlinks.relatedpostid AS post_id,
        COUNT(*) AS incoming_link_count
    FROM postlinks
    GROUP BY postlinks.relatedpostid
),
post_metrics AS (
    SELECT
        p.id,
        p.posttypeid,
        date_trunc('month', p.creationdate) AS month,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(v.upvote_count, 0) AS upvote_count,
        COALESCE(v.downvote_count, 0) AS downvote_count,
        COALESCE(v.total_bounty, 0) AS total_bounty,
        COALESCE(h.history_count, 0) AS history_count,
        COALESCE(l.outgoing_link_count, 0) AS outgoing_link_count,
        COALESCE(l.duplicate_link_count, 0) AS duplicate_link_count,
        COALESCE(r.incoming_link_count, 0) AS incoming_link_count,
        (p.score + p.viewcount + COALESCE(v.vote_count, 0) + COALESCE(h.history_count, 0) + COALESCE(l.outgoing_link_count, 0) + COALESCE(r.incoming_link_count, 0)) AS total_engagement
    FROM posts p
    LEFT JOIN vote_agg v ON v.post_id = p.id
    LEFT JOIN history_agg h ON h.post_id = p.id
    LEFT JOIN link_agg l ON l.post_id = p.id
    LEFT JOIN related_link_agg r ON r.post_id = p.id
    WHERE p.posttypeid IN (1, 2)
)
SELECT
    id,
    posttypeid,
    month,
    score,
    viewcount,
    answercount,
    commentcount,
    favoritecount,
    vote_count,
    upvote_count,
    downvote_count,
    total_bounty,
    history_count,
    outgoing_link_count,
    duplicate_link_count,
    incoming_link_count,
    total_engagement,
    ROW_NUMBER() OVER (PARTITION BY posttypeid, month ORDER BY total_engagement DESC) AS engagement_rank
FROM post_metrics
ORDER BY total_engagement DESC
LIMIT 100
