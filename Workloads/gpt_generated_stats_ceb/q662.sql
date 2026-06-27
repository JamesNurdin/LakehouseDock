WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(bountyamount) AS bounty_sum
    FROM votes
    GROUP BY postid
),
user_post_agg AS (
    SELECT
        p.owneruserid AS owner_userid,
        COUNT(*) AS post_cnt,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS view_cnt_sum,
        SUM(p.answercount) AS answer_cnt_sum,
        SUM(p.commentcount) AS post_comment_cnt,
        COALESCE(SUM(ca.comment_cnt), 0) AS total_comments_on_posts,
        COALESCE(SUM(ca.comment_score_sum), 0) AS total_comment_score_on_posts,
        COALESCE(SUM(va.vote_cnt), 0) AS total_votes_on_posts,
        COALESCE(SUM(va.upvote_cnt), 0) AS total_upvotes_on_posts,
        COALESCE(SUM(va.downvote_cnt), 0) AS total_downvotes_on_posts,
        COALESCE(SUM(va.bounty_sum), 0) AS total_bounty_on_posts
    FROM posts p
    LEFT JOIN comment_agg ca ON ca.postid = p.id
    LEFT JOIN vote_agg va ON va.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    upa.post_cnt,
    upa.post_score_sum,
    upa.post_score_sum / NULLIF(upa.post_cnt, 0) AS avg_score_per_post,
    upa.view_cnt_sum,
    upa.answer_cnt_sum,
    upa.post_comment_cnt,
    upa.total_comments_on_posts,
    upa.total_comment_score_on_posts,
    upa.total_votes_on_posts,
    upa.total_upvotes_on_posts,
    upa.total_downvotes_on_posts,
    upa.total_bounty_on_posts
FROM users u
LEFT JOIN user_post_agg upa ON upa.owner_userid = u.id
ORDER BY upa.post_score_sum DESC
LIMIT 20
