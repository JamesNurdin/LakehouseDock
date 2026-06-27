WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_count,
        p.id AS post_id,
        p.score AS post_score,
        p.answercount AS post_answercount,
        p.owneruserid AS owner_user_id
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
post_votes AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_cnt
    FROM votes v
    GROUP BY v.postid
),
owner_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_cnt
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    tp.tag_id,
    tp.tag_count,
    COUNT(DISTINCT tp.post_id) AS num_posts,
    SUM(tp.post_score) AS total_post_score,
    AVG(tp.post_answercount) AS avg_answer_count,
    COUNT(DISTINCT tp.owner_user_id) AS num_distinct_owners,
    SUM(ob.badge_cnt) AS total_badges_of_owners,
    SUM(pv.vote_cnt) AS total_votes_on_posts
FROM tag_posts tp
LEFT JOIN post_votes pv ON tp.post_id = pv.post_id
LEFT JOIN owner_badges ob ON tp.owner_user_id = ob.user_id
GROUP BY tp.tag_id, tp.tag_count
ORDER BY total_post_score DESC
LIMIT 20
