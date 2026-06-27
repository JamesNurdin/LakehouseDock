WITH person_post_stats AS (
    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.gender,
        COUNT(*) AS post_count,
        SUM(po.length) AS total_length,
        AVG(po.length) AS avg_length,
        COUNT(DISTINCT po.language) AS distinct_languages,
        MIN(po.creation_date) AS first_post_date,
        MAX(po.creation_date) AS latest_post_date
    FROM person p
    JOIN post po
      ON po.creator_person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name, p.gender
)
SELECT
    id,
    first_name,
    last_name,
    gender,
    post_count,
    total_length,
    avg_length,
    distinct_languages,
    first_post_date,
    latest_post_date,
    RANK() OVER (ORDER BY total_length DESC) AS total_length_rank
FROM person_post_stats
ORDER BY total_length DESC
LIMIT 10
