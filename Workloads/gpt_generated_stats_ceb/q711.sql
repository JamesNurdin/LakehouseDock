WITH comment_counts AS (
    SELECT postid, count(*) AS comment_count
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT postid, count(*) AS vote_count
    FROM votes
    GROUP BY postid
)
SELECT
    posts.posttypeid,
    date_trunc('month', posts.creationdate) AS post_month,
    count(DISTINCT posts.id) AS total_posts,
    avg(posts.score) AS avg_post_score,
    coalesce(sum(comment_counts.comment_count), 0) AS total_comments,
    coalesce(sum(vote_counts.vote_count), 0) AS total_votes,
    avg(owner.reputation) AS avg_owner_reputation
FROM posts
LEFT JOIN comment_counts
    ON comment_counts.postid = posts.id
LEFT JOIN vote_counts
    ON vote_counts.postid = posts.id
LEFT JOIN users AS owner
    ON posts.owneruserid = owner.id
GROUP BY
    posts.posttypeid,
    date_trunc('month', posts.creationdate)
ORDER BY
    posts.posttypeid,
    post_month
