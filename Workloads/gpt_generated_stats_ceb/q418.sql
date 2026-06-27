WITH comment_stats AS (
    SELECT
        c.postid AS post_id,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS sum_comment_score,
        COUNT(DISTINCT c.userid) AS distinct_comment_authors,
        AVG(u.reputation) AS avg_comment_author_reputation
    FROM comments c
    LEFT JOIN users u ON u.id = c.userid
    GROUP BY c.postid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    cs.comment_count,
    cs.avg_comment_score,
    cs.sum_comment_score,
    cs.distinct_comment_authors,
    cs.avg_comment_author_reputation,
    u_owner.reputation AS owner_reputation,
    u_owner.upvotes AS owner_upvotes,
    u_owner.downvotes AS owner_downvotes,
    u_editor.reputation AS editor_reputation,
    u_editor.upvotes AS editor_upvotes,
    u_editor.downvotes AS editor_downvotes,
    CASE
        WHEN p.answercount > 0 THEN cs.comment_count / p.answercount
        ELSE NULL
    END AS comment_to_answer_ratio
FROM posts p
LEFT JOIN comment_stats cs ON cs.post_id = p.id
LEFT JOIN users u_owner ON u_owner.id = p.owneruserid
LEFT JOIN users u_editor ON u_editor.id = p.lasteditoruserid
ORDER BY cs.comment_count DESC NULLS LAST, p.score DESC
LIMIT 100
