WITH tag_excerpt AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_count,
        tags.excerptpostid,
        posts.id AS post_id,
        posts.creationdate,
        posts.score,
        posts.viewcount,
        posts.owneruserid,
        posts.answercount,
        posts.commentcount,
        posts.favoritecount,
        posts.lasteditoruserid,
        EXTRACT(year FROM posts.creationdate) AS creation_year
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    WHERE posts.posttypeid = 1
      AND tags.count > 0
),
tag_stats AS (
    SELECT
        tag_id,
        tag_count,
        creation_year,
        SUM(score) AS total_score,
        AVG(viewcount) AS avg_viewcount,
        SUM(answercount) AS total_answers,
        COUNT(*) AS excerpt_post_count
    FROM tag_excerpt
    GROUP BY tag_id, tag_count, creation_year
)
SELECT
    tag_id,
    tag_count,
    creation_year,
    total_score,
    avg_viewcount,
    total_answers,
    excerpt_post_count,
    ROW_NUMBER() OVER (PARTITION BY creation_year ORDER BY total_score DESC) AS rank_by_score_in_year
FROM tag_stats
ORDER BY total_score DESC
LIMIT 100
