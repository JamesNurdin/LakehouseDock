WITH post_counts AS (
    SELECT
        p.location_country_id AS country_id,
        p.language,
        COUNT(*) AS language_post_count
    FROM post p
    GROUP BY p.location_country_id, p.language
),
country_posts AS (
    SELECT
        pc.country_id,
        pc.language,
        pc.language_post_count,
        RANK() OVER (PARTITION BY pc.country_id ORDER BY pc.language_post_count DESC) AS lang_rank
    FROM post_counts pc
),
top_language AS (
    SELECT
        country_id,
        language AS top_language,
        language_post_count AS top_language_post_count
    FROM country_posts
    WHERE lang_rank = 1
),
comment_counts AS (
    SELECT
        c.location_country_id AS country_id,
        COUNT(*) AS comment_count
    FROM comment c
    GROUP BY c.location_country_id
),
post_total AS (
    SELECT
        p.location_country_id AS country_id,
        COUNT(*) AS post_total
    FROM post p
    GROUP BY p.location_country_id
)
SELECT
    pl.id AS country_id,
    pl.name AS country_name,
    COALESCE(pt.post_total, 0) AS total_posts,
    COALESCE(cc.comment_count, 0) AS total_comments,
    tl.top_language,
    tl.top_language_post_count
FROM place pl
LEFT JOIN post_total pt ON pl.id = pt.country_id
LEFT JOIN comment_counts cc ON pl.id = cc.country_id
LEFT JOIN top_language tl ON pl.id = tl.country_id
WHERE pl.type = 'Country'
ORDER BY total_comments DESC
LIMIT 10
