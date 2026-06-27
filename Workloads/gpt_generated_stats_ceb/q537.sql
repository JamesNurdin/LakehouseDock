WITH post_stats AS (
    SELECT
        year(p.creationdate) AS year,
        COUNT(*) AS total_posts,
        SUM(p.score) AS total_post_score,
        AVG(p.viewcount) AS avg_viewcount,
        COUNT(DISTINCT p.owneruserid) AS distinct_authors
    FROM posts p
    GROUP BY year(p.creationdate)
),
comment_stats AS (
    SELECT
        year(p.creationdate) AS year,
        COUNT(c.id) AS total_comments,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY year(p.creationdate)
),
vote_stats AS (
    SELECT
        year(p.creationdate) AS year,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes,
        SUM(v.bountyamount) AS total_bounty
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY year(p.creationdate)
),
badge_stats AS (
    SELECT
        year(b.date) AS year,
        COUNT(b.id) AS total_badges,
        COUNT(DISTINCT b.userid) AS distinct_badge_earners
    FROM badges b
    GROUP BY year(b.date)
),
edit_stats AS (
    SELECT
        year(p.creationdate) AS year,
        COUNT(ph.id) AS total_edit_events,
        COUNT(DISTINCT ph.userid) AS distinct_editors
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY year(p.creationdate)
)
SELECT
    ps.year,
    ps.total_posts,
    ps.total_post_score,
    ps.avg_viewcount,
    ps.distinct_authors,
    cs.total_comments,
    cs.avg_comment_score,
    cs.distinct_commenters,
    vs.total_votes,
    vs.upvotes,
    vs.downvotes,
    vs.total_bounty,
    bs.total_badges,
    bs.distinct_badge_earners,
    es.total_edit_events,
    es.distinct_editors
FROM post_stats ps
LEFT JOIN comment_stats cs ON ps.year = cs.year
LEFT JOIN vote_stats vs ON ps.year = vs.year
LEFT JOIN badge_stats bs ON ps.year = bs.year
LEFT JOIN edit_stats es ON ps.year = es.year
ORDER BY ps.year
