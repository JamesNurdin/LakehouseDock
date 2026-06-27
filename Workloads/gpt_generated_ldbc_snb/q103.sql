WITH alumni_posts AS (
    SELECT
        o.id AS university_id,
        o.name AS university_name,
        pl.id AS university_place_id,
        pl.name AS university_place_name,
        p.id AS person_id,
        post.id AS post_id,
        post.length AS post_length
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN post ON post.creator_person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    JOIN place pl ON o.location_place_id = pl.id
    WHERE o.type = 'University'
)
SELECT
    university_id,
    university_name,
    university_place_name,
    COUNT(post_id) AS total_posts,
    AVG(post_length) AS avg_post_length,
    COUNT(DISTINCT person_id) AS distinct_alumni_posters,
    RANK() OVER (ORDER BY COUNT(post_id) DESC) AS university_rank
FROM alumni_posts
GROUP BY university_id, university_name, university_place_name
ORDER BY total_posts DESC
LIMIT 10
