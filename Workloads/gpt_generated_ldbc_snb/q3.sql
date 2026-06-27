WITH post_like_counts AS (
    SELECT
        plp.post_id,
        COUNT(*) AS like_cnt,
        COUNT(DISTINCT plp.person_id) AS distinct_liker_cnt
    FROM person_likes_post plp
    GROUP BY plp.post_id
)
SELECT
    p.id AS post_id,
    p.creator_person_id,
    p.language,
    p.length,
    p.browser_used,
    p.location_country_id,
    post_like_counts.like_cnt,
    post_like_counts.distinct_liker_cnt,
    (post_like_counts.like_cnt * 1.0) / NULLIF(p.length, 0) AS likes_per_character
FROM post_like_counts
JOIN post p
    ON post_like_counts.post_id = p.id
ORDER BY post_like_counts.like_cnt DESC
LIMIT 10
