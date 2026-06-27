WITH comment_counts AS (
    SELECT postid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT postid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY postid
),
posthistory_counts AS (
    SELECT posthistorytypeid AS postid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
out_link_counts AS (
    SELECT postid,
           COUNT(*) AS out_link_count
    FROM postlinks
    GROUP BY postid
),
in_link_counts AS (
    SELECT relatedpostid AS postid,
           COUNT(*) AS in_link_count
    FROM postlinks
    GROUP BY relatedpostid
),
tag_counts AS (
    SELECT excerptpostid AS postid,
           COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    posts.id,
    posts.posttypeid,
    posts.creationdate,
    posts.score,
    ROW_NUMBER() OVER (ORDER BY posts.score DESC) AS score_rank,
    AVG(posts.score) OVER () AS avg_score_all,
    posts.viewcount,
    posts.owneruserid,
    owner.reputation AS owner_reputation,
    posts.lasteditoruserid,
    last_editor.reputation AS last_editor_reputation,
    COALESCE(comment_counts.comment_count, 0) AS comment_count,
    COALESCE(vote_counts.vote_count, 0) AS vote_count,
    COALESCE(vote_counts.upvote_count, 0) AS upvote_count,
    COALESCE(vote_counts.downvote_count, 0) AS downvote_count,
    COALESCE(posthistory_counts.posthistory_count, 0) AS posthistory_count,
    COALESCE(out_link_counts.out_link_count, 0) AS out_link_count,
    COALESCE(in_link_counts.in_link_count, 0) AS in_link_count,
    COALESCE(tag_counts.tag_count, 0) AS tag_count
FROM posts
LEFT JOIN users AS owner
    ON posts.owneruserid = owner.id
LEFT JOIN users AS last_editor
    ON posts.lasteditoruserid = last_editor.id
LEFT JOIN comment_counts
    ON comment_counts.postid = posts.id
LEFT JOIN vote_counts
    ON vote_counts.postid = posts.id
LEFT JOIN posthistory_counts
    ON posthistory_counts.postid = posts.id
LEFT JOIN out_link_counts
    ON out_link_counts.postid = posts.id
LEFT JOIN in_link_counts
    ON in_link_counts.postid = posts.id
LEFT JOIN tag_counts
    ON tag_counts.postid = posts.id
ORDER BY posts.creationdate DESC
LIMIT 100
