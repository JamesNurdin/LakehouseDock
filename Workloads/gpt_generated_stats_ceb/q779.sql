WITH
    post_metrics AS (
        SELECT
            year(p.creationdate) AS year,
            count(*) AS total_posts,
            avg(p.score) AS avg_post_score,
            sum(p.viewcount) AS total_views,
            count(distinct p.owneruserid) AS distinct_owners,
            count(distinct p.lasteditoruserid) AS distinct_editors
        FROM posts p
        GROUP BY year(p.creationdate)
    ),
    comment_metrics AS (
        SELECT
            year(c.creationdate) AS year,
            count(*) AS total_comments,
            avg(c.score) AS avg_comment_score,
            count(distinct c.userid) AS distinct_commenters
        FROM comments c
        GROUP BY year(c.creationdate)
    ),
    vote_metrics AS (
        SELECT
            year(v.creationdate) AS year,
            count(*) AS total_votes,
            sum(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes,
            sum(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes,
            count(distinct v.userid) AS distinct_voters
        FROM votes v
        GROUP BY year(v.creationdate)
    ),
    badge_metrics AS (
        SELECT
            year(b.date) AS year,
            count(*) AS total_badges,
            count(distinct b.userid) AS distinct_badge_earners
        FROM badges b
        GROUP BY year(b.date)
    ),
    tag_metrics AS (
        SELECT
            year(p.creationdate) AS year,
            count(distinct t.id) AS distinct_tags
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY year(p.creationdate)
    ),
    postlink_metrics AS (
        SELECT
            year(pl.creationdate) AS year,
            count(*) AS total_postlinks
        FROM postlinks pl
        GROUP BY year(pl.creationdate)
    )
SELECT
    COALESCE(pm.year, cm.year, vm.year, bm.year, tm.year, plm.year) AS year,
    pm.total_posts,
    pm.avg_post_score,
    pm.total_views,
    pm.distinct_owners,
    pm.distinct_editors,
    cm.total_comments,
    cm.avg_comment_score,
    cm.distinct_commenters,
    vm.total_votes,
    vm.upvotes,
    vm.downvotes,
    vm.distinct_voters,
    bm.total_badges,
    bm.distinct_badge_earners,
    tm.distinct_tags,
    plm.total_postlinks
FROM post_metrics pm
FULL OUTER JOIN comment_metrics cm ON pm.year = cm.year
FULL OUTER JOIN vote_metrics vm ON COALESCE(pm.year, cm.year) = vm.year
FULL OUTER JOIN badge_metrics bm ON COALESCE(pm.year, cm.year, vm.year) = bm.year
FULL OUTER JOIN tag_metrics tm ON COALESCE(pm.year, cm.year, vm.year, bm.year) = tm.year
FULL OUTER JOIN postlink_metrics plm ON COALESCE(pm.year, cm.year, vm.year, bm.year, tm.year) = plm.year
ORDER BY year
