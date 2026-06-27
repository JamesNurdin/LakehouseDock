WITH comment_person_country AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.location_country_id AS country_id,
        c.length AS comment_length,
        p.language,
        pc.name AS country_name,
        cont.name AS continent_name
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN place pc ON c.location_country_id = pc.id
    LEFT JOIN place cont ON pc.part_of_place_id = cont.id
),
reply_counts AS (
    SELECT
        parent.location_country_id AS country_id,
        COUNT(*) AS reply_count
    FROM comment reply
    JOIN comment parent ON reply.parent_comment_id = parent.id
    GROUP BY parent.location_country_id
),
language_rank AS (
    SELECT
        country_id,
        language,
        COUNT(*) AS lang_cnt,
        ROW_NUMBER() OVER (PARTITION BY country_id ORDER BY COUNT(*) DESC) AS rn
    FROM comment_person_country
    GROUP BY country_id, language
)
SELECT
    cpc.country_id,
    cpc.country_name,
    cpc.continent_name,
    COUNT(*) AS total_comments,
    COALESCE(rc.reply_count, 0) AS total_replies,
    AVG(cpc.comment_length) AS avg_comment_length,
    COUNT(DISTINCT cpc.creator_person_id) AS distinct_commenters,
    lr.language AS top_language_by_comments
FROM comment_person_country cpc
LEFT JOIN reply_counts rc ON cpc.country_id = rc.country_id
LEFT JOIN language_rank lr ON cpc.country_id = lr.country_id AND lr.rn = 1
GROUP BY
    cpc.country_id,
    cpc.country_name,
    cpc.continent_name,
    rc.reply_count,
    lr.language
ORDER BY total_comments DESC
LIMIT 20
