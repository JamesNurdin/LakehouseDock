WITH post_likes AS (
    SELECT
        plp.post_id,
        COUNT(*) AS like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_liker_count,
        COUNT(*) FILTER (WHERE per.gender = 'male') AS male_like_count,
        COUNT(*) FILTER (WHERE per.gender = 'female') AS female_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    JOIN person per ON plp.person_id = per.id
    GROUP BY plp.post_id
),
post_comments AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenter_count,
        COUNT(DISTINCT c.creator_person_id) FILTER (WHERE per.gender = 'male') AS distinct_male_commenter_count,
        COUNT(DISTINCT c.creator_person_id) FILTER (WHERE per.gender = 'female') AS distinct_female_commenter_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN person per ON c.creator_person_id = per.id
    GROUP BY c.parent_post_id
),
post_creator AS (
    SELECT
        p.id AS post_id,
        per.gender AS creator_gender,
        per.language AS creator_language
    FROM post p
    JOIN person per ON p.creator_person_id = per.id
)
SELECT
    pc.post_id,
    pc.creator_gender,
    pc.creator_language,
    COALESCE(pl.like_count, 0) AS like_count,
    COALESCE(pl.distinct_liker_count, 0) AS distinct_liker_count,
    COALESCE(pl.male_like_count, 0) AS male_like_count,
    COALESCE(pl.female_like_count, 0) AS female_like_count,
    COALESCE(pcmt.comment_count, 0) AS comment_count,
    COALESCE(pcmt.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pcmt.distinct_commenter_count, 0) AS distinct_commenter_count,
    COALESCE(pcmt.distinct_male_commenter_count, 0) AS distinct_male_commenter_count,
    COALESCE(pcmt.distinct_female_commenter_count, 0) AS distinct_female_commenter_count,
    CASE WHEN COALESCE(pcmt.comment_count, 0) = 0 THEN NULL
         ELSE COALESCE(pl.like_count, 0) * 1.0 / COALESCE(pcmt.comment_count, 0)
    END AS likes_per_comment_ratio
FROM post_creator pc
LEFT JOIN post_likes pl ON pc.post_id = pl.post_id
LEFT JOIN post_comments pcmt ON pc.post_id = pcmt.post_id
ORDER BY like_count DESC, comment_count DESC
LIMIT 100
