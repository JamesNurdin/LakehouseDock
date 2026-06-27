WITH member_info AS (
    SELECT fmp.forum_id,
           p.id AS person_id,
           p.gender,
           p.location_city_id
    FROM forum_has_member_person fmp
    JOIN person p ON fmp.person_id = p.id
),
interest_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
like_counts AS (
    SELECT person_id,
           COUNT(DISTINCT post_id) AS liked_post_count
    FROM person_likes_post
    GROUP BY person_id
)
SELECT
    mi.forum_id,
    COUNT(DISTINCT mi.person_id) AS total_members,
    COUNT(DISTINCT CASE WHEN ic.interest_tag_count IS NOT NULL THEN mi.person_id END) AS members_with_interest,
    COUNT(DISTINCT CASE WHEN lc.liked_post_count IS NOT NULL THEN mi.person_id END) AS members_who_liked,
    AVG(COALESCE(ic.interest_tag_count, 0)) AS avg_interest_tags_per_member,
    AVG(COALESCE(lc.liked_post_count, 0)) AS avg_liked_posts_per_member,
    COUNT(DISTINCT CASE WHEN mi.gender = 'male' THEN mi.person_id END) AS male_members,
    COUNT(DISTINCT CASE WHEN mi.gender = 'female' THEN mi.person_id END) AS female_members
FROM member_info mi
LEFT JOIN interest_counts ic ON mi.person_id = ic.person_id
LEFT JOIN like_counts lc ON mi.person_id = lc.person_id
GROUP BY mi.forum_id
ORDER BY total_members DESC
LIMIT 100
