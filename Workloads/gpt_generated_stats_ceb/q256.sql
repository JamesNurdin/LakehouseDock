WITH comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY postid
),
vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY postid
)
SELECT
    p.posttypeid,
    COUNT(p.id) AS total_posts,
    AVG(p.score) AS avg_post_score,
    COALESCE(SUM(cs.comment_count), 0) AS total_comments,
    AVG(COALESCE(cs.comment_count, 0)) AS avg_comments_per_post,
    AVG(cs.avg_comment_score) AS avg_comment_score,
    COALESCE(SUM(vs.vote_count), 0) AS total_votes,
    AVG(COALESCE(vs.vote_count, 0)) AS avg_votes_per_post,
    AVG(owner.reputation) AS avg_owner_reputation,
    AVG(editor.reputation) AS avg_last_editor_reputation
FROM posts p
LEFT JOIN comment_stats cs ON cs.postid = p.id
LEFT JOIN vote_stats vs ON vs.postid = p.id
LEFT JOIN users owner ON p.owneruserid = owner.id
LEFT JOIN users editor ON p.lasteditoruserid = editor.id
GROUP BY p.posttypeid
ORDER BY p.posttypeid
