-- For each tag, compute statistics about the comments that have that tag:
-- number of comments, average comment length, total likes on those comments,
-- distinct comment creators, distinct countries of comment origin, and the list of country names.
WITH comment_tag_stats AS (
    SELECT
        cht.tag_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        c.location_country_id,
        COUNT(plc.person_id) AS like_count
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY cht.tag_id, c.id, c.length, c.creator_person_id, c.location_country_id
)
SELECT
    cts.tag_id,
    COUNT(DISTINCT cts.comment_id) AS num_comments,
    AVG(cts.comment_length) AS avg_comment_length,
    SUM(cts.like_count) AS total_likes,
    COUNT(DISTINCT cts.creator_person_id) AS distinct_comment_creators,
    COUNT(DISTINCT cts.location_country_id) AS distinct_countries,
    ARRAY_AGG(DISTINCT p.name) AS country_names
FROM comment_tag_stats cts
JOIN place p
    ON cts.location_country_id = p.id
GROUP BY cts.tag_id
ORDER BY total_likes DESC
LIMIT 10
