WITH post_user AS (
    SELECT
        posts.id AS post_id,
        posts.posttypeid,
        posts.creationdate AS post_creationdate,
        posts.score,
        posts.viewcount,
        posts.owneruserid,
        posts.lasteditoruserid,
        posts.answercount,
        posts.commentcount,
        posts.favoritecount,
        owner.reputation AS owner_reputation,
        editor.reputation AS editor_reputation
    FROM posts
    LEFT JOIN users AS owner
        ON posts.owneruserid = owner.id
    LEFT JOIN users AS editor
        ON posts.lasteditoruserid = editor.id
)
SELECT
    posttypeid,
    COUNT(post_id) AS post_count,
    AVG(score) AS avg_score,
    SUM(viewcount) AS total_views,
    AVG(owner_reputation) AS avg_owner_reputation,
    AVG(editor_reputation) AS avg_editor_reputation,
    SUM(CASE WHEN answercount > 0 THEN 1 ELSE 0 END) AS posts_with_answers,
    MAX(score) AS max_score,
    MIN(score) AS min_score
FROM post_user
GROUP BY posttypeid
ORDER BY posttypeid
