WITH post_agg AS (
    SELECT
        year(p.creationdate) AS post_year,
        count(*) AS total_posts,
        sum(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        sum(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        sum(p.score) AS total_score,
        sum(p.viewcount) AS total_viewcount,
        count(DISTINCT p.owneruserid) AS distinct_owners
    FROM posts p
    GROUP BY year(p.creationdate)
),
comment_agg AS (
    SELECT
        year(p.creationdate) AS post_year,
        count(*) AS comment_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY year(p.creationdate)
),
vote_agg AS (
    SELECT
        year(p.creationdate) AS post_year,
        count(*) AS vote_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY year(p.creationdate)
),
owner_rep_agg AS (
    SELECT
        post_year,
        sum(reputation) AS total_owner_reputation,
        avg(reputation) AS avg_owner_reputation,
        count(*) AS distinct_owner_count
    FROM (
        SELECT DISTINCT year(p.creationdate) AS post_year, u.id AS user_id, u.reputation
        FROM posts p
        JOIN users u ON p.owneruserid = u.id
    ) o
    GROUP BY post_year
)
SELECT
    pa.post_year,
    pa.total_posts,
    pa.total_questions,
    pa.total_answers,
    pa.total_score,
    pa.total_viewcount,
    pa.distinct_owners,
    coalesce(ca.comment_count, 0) AS comment_count,
    coalesce(va.vote_count, 0) AS vote_count,
    coalesce(oragg.total_owner_reputation, 0) AS total_owner_reputation,
    coalesce(oragg.avg_owner_reputation, 0) AS avg_owner_reputation,
    coalesce(oragg.distinct_owner_count, 0) AS distinct_owner_count
FROM post_agg pa
LEFT JOIN comment_agg ca ON pa.post_year = ca.post_year
LEFT JOIN vote_agg va ON pa.post_year = va.post_year
LEFT JOIN owner_rep_agg oragg ON pa.post_year = oragg.post_year
ORDER BY pa.post_year
