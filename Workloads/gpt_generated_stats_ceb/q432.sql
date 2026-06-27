WITH comment_agg AS (
    SELECT
        comments.postid AS postid,
        COUNT(comments.id) AS comment_cnt,
        SUM(comments.score) AS comment_score
    FROM comments
    GROUP BY comments.postid
),
vote_agg AS (
    SELECT
        votes.postid AS postid,
        COUNT(votes.id) AS vote_cnt,
        SUM(votes.bountyamount) AS total_bounty
    FROM votes
    GROUP BY votes.postid
),
postlink_out_agg AS (
    SELECT
        postlinks.postid AS postid,
        COUNT(postlinks.id) AS outgoing_links
    FROM postlinks
    GROUP BY postlinks.postid
),
postlink_in_agg AS (
    SELECT
        postlinks.relatedpostid AS postid,
        COUNT(postlinks.id) AS incoming_links
    FROM postlinks
    GROUP BY postlinks.relatedpostid
),
tag_agg AS (
    SELECT
        tags.excerptpostid AS postid,
        SUM(tags.count) AS tag_usage_sum
    FROM tags
    GROUP BY tags.excerptpostid
)
SELECT
    posts.id,
    posts.posttypeid,
    posts.creationdate,
    posts.score AS post_score,
    posts.viewcount,
    posts.answercount,
    posts.favoritecount,
    COALESCE(comment_agg.comment_cnt, 0) AS comment_cnt,
    COALESCE(comment_agg.comment_score, 0) AS comment_score,
    COALESCE(vote_agg.vote_cnt, 0) AS vote_cnt,
    COALESCE(vote_agg.total_bounty, 0) AS total_bounty,
    COALESCE(postlink_out_agg.outgoing_links, 0) AS outgoing_links,
    COALESCE(postlink_in_agg.incoming_links, 0) AS incoming_links,
    COALESCE(tag_agg.tag_usage_sum, 0) AS tag_usage_sum,
    (posts.score
     + COALESCE(comment_agg.comment_score, 0)
     + COALESCE(vote_agg.total_bounty, 0)
     + COALESCE(postlink_out_agg.outgoing_links, 0)
     + COALESCE(postlink_in_agg.incoming_links, 0)
     + COALESCE(tag_agg.tag_usage_sum, 0)
    ) AS activity_score
FROM posts
LEFT JOIN comment_agg
    ON comment_agg.postid = posts.id
LEFT JOIN vote_agg
    ON vote_agg.postid = posts.id
LEFT JOIN postlink_out_agg
    ON postlink_out_agg.postid = posts.id
LEFT JOIN postlink_in_agg
    ON postlink_in_agg.postid = posts.id
LEFT JOIN tag_agg
    ON tag_agg.postid = posts.id
ORDER BY activity_score DESC
LIMIT 10
