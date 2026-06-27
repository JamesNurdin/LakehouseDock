WITH post_like_agg AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT plp.person_id) AS distinct_persons_post_like,
        COUNT(DISTINCT plp.post_id) AS distinct_posts_liked,
        SUM(post.length) AS total_post_length_liked,
        COUNT(plp.post_id) AS total_post_likes
    FROM person_has_interest_tag pht
    JOIN person p ON pht.person_id = p.id
    JOIN person_likes_post plp ON plp.person_id = p.id
    JOIN post ON plp.post_id = post.id
    GROUP BY pht.tag_id
),
comment_like_agg AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT plc.person_id) AS distinct_persons_comment_like,
        COUNT(DISTINCT plc.comment_id) AS distinct_comments_liked,
        SUM(comment.length) AS total_comment_length_liked,
        COUNT(plc.comment_id) AS total_comment_likes
    FROM person_has_interest_tag pht
    JOIN person p ON pht.person_id = p.id
    JOIN person_likes_comment plc ON plc.person_id = p.id
    JOIN comment ON plc.comment_id = comment.id
    GROUP BY pht.tag_id
)
SELECT
    tag.id AS tag_id,
    tag.name AS tag_name,
    COALESCE(post_like_agg.distinct_persons_post_like, 0) + COALESCE(comment_like_agg.distinct_persons_comment_like, 0) AS distinct_persons_who_liked,
    COALESCE(post_like_agg.distinct_posts_liked, 0) AS distinct_posts_liked,
    COALESCE(comment_like_agg.distinct_comments_liked, 0) AS distinct_comments_liked,
    COALESCE(post_like_agg.total_post_length_liked, 0) + COALESCE(comment_like_agg.total_comment_length_liked, 0) AS total_content_length_liked,
    COALESCE(post_like_agg.total_post_length_liked, 0) AS total_post_length_liked,
    COALESCE(comment_like_agg.total_comment_length_liked, 0) AS total_comment_length_liked,
    COALESCE(post_like_agg.total_post_likes, 0) + COALESCE(comment_like_agg.total_comment_likes, 0) AS total_likes
FROM tag
LEFT JOIN post_like_agg ON post_like_agg.tag_id = tag.id
LEFT JOIN comment_like_agg ON comment_like_agg.tag_id = tag.id
ORDER BY total_likes DESC
LIMIT 10
