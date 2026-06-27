WITH post_agg AS (
    SELECT
        posttypeid,
        COUNT(*) AS post_cnt,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        SUM(viewcount) AS post_view_sum,
        SUM(answercount) AS post_answer_sum,
        SUM(commentcount) AS post_comment_cnt,
        SUM(favoritecount) AS post_favorite_sum
    FROM posts
    GROUP BY posttypeid
),
comment_agg AS (
    SELECT
        p.posttypeid,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.posttypeid
),
vote_agg AS (
    SELECT
        p.posttypeid,
        COUNT(v.id) AS vote_cnt,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(CASE WHEN v.votetypeid = 8 THEN 1 ELSE 0 END) AS bountyvoted_cnt,
        SUM(v.bountyamount) AS bounty_amount_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.posttypeid
)
SELECT
    p.posttypeid,
    p.post_cnt,
    p.post_score_sum,
    p.post_score_avg,
    p.post_view_sum,
    p.post_answer_sum,
    p.post_comment_cnt,
    p.post_favorite_sum,
    COALESCE(c.comment_cnt, 0) AS comment_cnt,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(c.comment_score_avg, NULL) AS comment_score_avg,
    COALESCE(v.vote_cnt, 0) AS vote_cnt,
    COALESCE(v.upvote_cnt, 0) AS upvote_cnt,
    COALESCE(v.downvote_cnt, 0) AS downvote_cnt,
    COALESCE(v.bountyvoted_cnt, 0) AS bountyvoted_cnt,
    COALESCE(v.bounty_amount_sum, 0) AS bounty_amount_sum
FROM post_agg p
LEFT JOIN comment_agg c ON p.posttypeid = c.posttypeid
LEFT JOIN vote_agg v ON p.posttypeid = v.posttypeid
ORDER BY p.posttypeid
