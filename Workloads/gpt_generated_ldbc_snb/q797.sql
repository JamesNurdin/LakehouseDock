/*
  Analytical query: count likes per post by the city of the users who liked the post
  and rank the top‑5 most liked posts within each city.
*/
WITH city_post_likes AS (
    SELECT
        p.location_city_id,
        plp.post_id,
        COUNT(*) AS likes_count
    FROM person p
    JOIN person_likes_post plp
        ON plp.person_id = p.id
    GROUP BY p.location_city_id, plp.post_id
),
ranked_posts AS (
    SELECT
        location_city_id,
        post_id,
        likes_count,
        ROW_NUMBER() OVER (PARTITION BY location_city_id ORDER BY likes_count DESC) AS rank_in_city
    FROM city_post_likes
)
SELECT
    location_city_id,
    post_id,
    likes_count,
    rank_in_city
FROM ranked_posts
WHERE rank_in_city <= 5
ORDER BY location_city_id, rank_in_city
