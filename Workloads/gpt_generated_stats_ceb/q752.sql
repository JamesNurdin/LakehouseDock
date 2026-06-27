WITH vote_agg AS (
    SELECT
        votes.postid AS post_id,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT votes.userid) AS distinct_voter_count,
        SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY votes.postid
),
history_agg AS (
    SELECT
        posthistory.posthistorytypeid AS post_id,
        COUNT(*) AS history_count,
        COUNT(DISTINCT posthistory.userid) AS distinct_user_history_count
    FROM posthistory
    GROUP BY posthistory.posthistorytypeid
),
outlink_agg AS (
    SELECT
        postlinks.postid AS post_id,
        COUNT(*) AS outlink_count
    FROM postlinks
    GROUP BY postlinks.postid
),
inlink_agg AS (
    SELECT
        postlinks.relatedpostid AS post_id,
        COUNT(*) AS inlink_count
    FROM postlinks
    GROUP BY postlinks.relatedpostid
),
tag_agg AS (
    SELECT
        tags.excerptpostid AS post_id,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY tags.excerptpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(h.history_count, 0) AS history_count,
    COALESCE(h.distinct_user_history_count, 0) AS distinct_user_history_count,
    COALESCE(o.outlink_count, 0) AS outlink_count,
    COALESCE(i.inlink_count, 0) AS inlink_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(v.vote_count, 0) DESC, COALESCE(h.history_count, 0) DESC) AS activity_rank
FROM posts AS p
LEFT JOIN vote_agg AS v ON v.post_id = p.id
LEFT JOIN history_agg AS h ON h.post_id = p.id
LEFT JOIN outlink_agg AS o ON o.post_id = p.id
LEFT JOIN inlink_agg AS i ON i.post_id = p.id
LEFT JOIN tag_agg AS t ON t.post_id = p.id
ORDER BY activity_rank
LIMIT 100
