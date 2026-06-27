WITH post_stats AS (
    SELECT
        year(p.creationdate) AS post_year,
        COUNT(*) AS total_posts,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        COUNT(DISTINCT p.owneruserid) AS distinct_authors
    FROM posts p
    GROUP BY year(p.creationdate)
),
vote_stats AS (
    SELECT
        year(p.creationdate) AS post_year,
        COUNT(v.id) AS total_votes,
        COUNT(DISTINCT v.userid) AS distinct_voters
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY year(p.creationdate)
),
badge_stats AS (
    SELECT
        year(u.creationdate) AS user_year,
        COUNT(DISTINCT b.userid) AS users_with_badge,
        COUNT(b.id) AS total_badges
    FROM badges b
    JOIN users u ON b.userid = u.id
    GROUP BY year(u.creationdate)
),
tag_stats AS (
    SELECT
        year(p.creationdate) AS post_year,
        COUNT(DISTINCT t.id) AS distinct_tags
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY year(p.creationdate)
),
comment_stats AS (
    SELECT
        year(p.creationdate) AS post_year,
        COUNT(c.id) AS total_comments,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY year(p.creationdate)
)
SELECT
    COALESCE(ps.post_year, vs.post_year, bs.user_year, ts.post_year, cs.post_year) AS year,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.avg_score, 0) AS avg_post_score,
    COALESCE(ps.total_views, 0) AS total_views,
    COALESCE(ps.distinct_authors, 0) AS distinct_authors,
    COALESCE(vs.total_votes, 0) AS total_votes,
    COALESCE(vs.distinct_voters, 0) AS distinct_voters,
    COALESCE(bs.users_with_badge, 0) AS users_with_badge,
    COALESCE(bs.total_badges, 0) AS total_badges,
    COALESCE(ts.distinct_tags, 0) AS distinct_tags,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(cs.avg_comment_score, 0) AS avg_comment_score
FROM post_stats ps
FULL OUTER JOIN vote_stats vs ON ps.post_year = vs.post_year
FULL OUTER JOIN badge_stats bs ON COALESCE(ps.post_year, vs.post_year) = bs.user_year
FULL OUTER JOIN tag_stats ts ON COALESCE(ps.post_year, vs.post_year, bs.user_year) = ts.post_year
FULL OUTER JOIN comment_stats cs ON COALESCE(ps.post_year, vs.post_year, bs.user_year, ts.post_year) = cs.post_year
ORDER BY year
