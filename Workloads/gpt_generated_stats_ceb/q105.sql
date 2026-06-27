WITH post_user_details AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        u_owner.reputation AS owner_reputation,
        u_owner.creationdate AS owner_creationdate,
        u_owner.views AS owner_views,
        u_owner.upvotes AS owner_upvotes,
        u_owner.downvotes AS owner_downvotes,
        u_editor.reputation AS editor_reputation,
        u_editor.creationdate AS editor_creationdate,
        u_editor.views AS editor_views,
        u_editor.upvotes AS editor_upvotes,
        u_editor.downvotes AS editor_downvotes
    FROM posts p
    LEFT JOIN users u_owner
        ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor
        ON p.lasteditoruserid = u_editor.id
    WHERE p.score > 0
)
SELECT
    pud.posttypeid,
    COUNT(*) AS post_count,
    AVG(pud.score) AS avg_score,
    SUM(pud.viewcount) AS total_views,
    AVG(pud.owner_reputation) AS avg_owner_reputation,
    AVG(pud.editor_reputation) AS avg_editor_reputation,
    SUM(CASE WHEN pud.lasteditoruserid <> pud.owneruserid THEN 1 ELSE 0 END) AS edited_by_others,
    AVG(CAST(pud.answercount AS double) / NULLIF(pud.viewcount, 0)) AS avg_answer_to_view_ratio
FROM post_user_details pud
GROUP BY pud.posttypeid
ORDER BY post_count DESC
LIMIT 5
