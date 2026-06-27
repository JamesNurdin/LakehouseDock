WITH comment_agg AS (
    SELECT
        comments.postid AS postid,
        COUNT(*) AS comment_count,
        SUM(comments.score) AS comment_score_sum
    FROM comments
    GROUP BY comments.postid
),
vote_agg AS (
    SELECT
        votes.postid AS postid,
        COUNT(*) AS vote_count,
        SUM(votes.votetypeid) AS vote_type_sum,
        COUNT(DISTINCT votes.userid) AS distinct_voter_count
    FROM votes
    GROUP BY votes.postid
),
link_agg AS (
    SELECT
        postlinks.postid AS postid,
        COUNT(*) AS outgoing_link_count
    FROM postlinks
    GROUP BY postlinks.postid
),
incoming_link_agg AS (
    SELECT
        postlinks.relatedpostid AS postid,
        COUNT(*) AS incoming_link_count
    FROM postlinks
    GROUP BY postlinks.relatedpostid
),
tag_agg AS (
    SELECT
        tags.excerptpostid AS postid,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY tags.excerptpostid
)
SELECT
    posts.id,
    posts.posttypeid,
    posts.creationdate,
    posts.score,
    posts.viewcount,
    COALESCE(comment_agg.comment_count, 0) AS comment_count,
    COALESCE(comment_agg.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vote_agg.vote_count, 0) AS vote_count,
    COALESCE(vote_agg.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(vote_agg.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(link_agg.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(incoming_link_agg.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(tag_agg.tag_count, 0) AS tag_count
FROM posts
LEFT JOIN comment_agg
    ON comment_agg.postid = posts.id
LEFT JOIN vote_agg
    ON vote_agg.postid = posts.id
LEFT JOIN link_agg
    ON link_agg.postid = posts.id
LEFT JOIN incoming_link_agg
    ON incoming_link_agg.postid = posts.id
LEFT JOIN tag_agg
    ON tag_agg.postid = posts.id
ORDER BY posts.score DESC, comment_count DESC
LIMIT 20
