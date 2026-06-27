WITH comment_agg AS (
    SELECT postid,
           COUNT(*) AS comment_cnt,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT postid,
           COUNT(*) AS vote_cnt,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
           SUM(COALESCE(bountyamount, 0)) AS bounty_sum
    FROM votes
    GROUP BY postid
),
link_agg AS (
    SELECT postid,
           COUNT(DISTINCT relatedpostid) AS linked_post_cnt
    FROM postlinks
    GROUP BY postid
)
SELECT
    p.posttypeid,
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS post_cnt,
    SUM(p.viewcount) AS total_views,
    AVG(p.answercount) AS avg_answer_count,
    SUM(p.score) AS total_post_score,
    AVG(p.score) AS avg_post_score,
    COALESCE(SUM(ca.comment_cnt), 0) AS total_comments,
    COALESCE(SUM(ca.comment_score_sum), 0) AS total_comment_score,
    COALESCE(SUM(va.vote_cnt), 0) AS total_votes,
    COALESCE(SUM(va.upvote_cnt), 0) AS total_upvotes,
    COALESCE(SUM(va.downvote_cnt), 0) AS total_downvotes,
    COALESCE(SUM(va.bounty_sum), 0) AS total_bounty,
    COALESCE(SUM(la.linked_post_cnt), 0) AS total_linked_posts,
    AVG(o.reputation) AS avg_owner_reputation
FROM posts p
LEFT JOIN tags t
    ON t.excerptpostid = p.id
LEFT JOIN comment_agg ca
    ON ca.postid = p.id
LEFT JOIN vote_agg va
    ON va.postid = p.id
LEFT JOIN link_agg la
    ON la.postid = p.id
LEFT JOIN users o
    ON p.owneruserid = o.id
GROUP BY p.posttypeid, t.id
ORDER BY post_cnt DESC, p.posttypeid
