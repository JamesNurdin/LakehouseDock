WITH tag_excerpts AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_count,
        tags.excerptpostid,
        posts.id AS post_id,
        posts.posttypeid,
        posts.creationdate,
        posts.score,
        posts.viewcount,
        posts.owneruserid,
        posts.answercount,
        posts.commentcount,
        posts.favoritecount,
        posts.lasteditoruserid
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
)
SELECT
    tag_excerpts.owneruserid,
    COUNT(DISTINCT tag_excerpts.tag_id) AS num_tags,
    SUM(tag_excerpts.tag_count) AS total_tag_use,
    AVG(tag_excerpts.score) AS avg_excerpt_score,
    AVG(tag_excerpts.viewcount) AS avg_excerpt_viewcount,
    SUM(tag_excerpts.answercount) AS total_answers,
    SUM(tag_excerpts.commentcount) AS total_comments,
    SUM(tag_excerpts.favoritecount) AS total_favorites,
    SUM(tag_excerpts.viewcount) / NULLIF(SUM(tag_excerpts.answercount), 0) AS view_per_answer_ratio
FROM tag_excerpts
WHERE tag_excerpts.posttypeid = 1
GROUP BY tag_excerpts.owneruserid
ORDER BY total_tag_use DESC
LIMIT 10
