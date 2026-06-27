WITH tag_excerpts AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        t.id AS tag_id,
        t.count AS tag_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
),
aggregated AS (
    SELECT
        posttypeid,
        COUNT(DISTINCT tag_id) AS distinct_tags,
        SUM(tag_count) AS total_tag_count,
        AVG(score) AS avg_excerpt_score,
        AVG(viewcount) AS avg_excerpt_viewcount,
        MAX(tag_count) AS max_tag_count
    FROM tag_excerpts
    GROUP BY posttypeid
)
SELECT
    posttypeid,
    distinct_tags,
    total_tag_count,
    avg_excerpt_score,
    avg_excerpt_viewcount,
    max_tag_count,
    ROW_NUMBER() OVER (ORDER BY total_tag_count DESC) AS rank_by_tag_count
FROM aggregated
ORDER BY rank_by_tag_count
