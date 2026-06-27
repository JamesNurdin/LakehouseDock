WITH post_metrics AS (
    SELECT
        year(posts.creationdate) AS year,
        count(*) AS post_count,
        avg(posts.score) AS avg_score,
        sum(posts.viewcount) AS total_views,
        sum(posts.favoritecount) AS total_favorites,
        sum(posts.answercount) AS total_answers
    FROM posts
    GROUP BY year(posts.creationdate)
),
comment_metrics AS (
    SELECT
        year(posts.creationdate) AS year,
        count(*) AS comment_count
    FROM comments
    JOIN posts ON comments.postid = posts.id
    GROUP BY year(posts.creationdate)
),
vote_metrics AS (
    SELECT
        year(posts.creationdate) AS year,
        count(*) AS vote_count,
        sum(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        sum(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    JOIN posts ON votes.postid = posts.id
    GROUP BY year(posts.creationdate)
),
badge_metrics AS (
    SELECT
        year(badges.date) AS year,
        count(*) AS badge_count
    FROM badges
    GROUP BY year(badges.date)
),
active_user_metrics AS (
    SELECT
        year_activity AS year,
        count(DISTINCT userid) AS active_user_count
    FROM (
        SELECT year(posts.creationdate) AS year_activity, posts.owneruserid AS userid FROM posts
        UNION ALL
        SELECT year(comments.creationdate) AS year_activity, comments.userid AS userid FROM comments
        UNION ALL
        SELECT year(votes.creationdate) AS year_activity, votes.userid AS userid FROM votes
        UNION ALL
        SELECT year(badges.date) AS year_activity, badges.userid AS userid FROM badges
    ) AS ua
    GROUP BY year_activity
)
SELECT
    COALESCE(pm.year, cm.year, vm.year, bm.year, au.year) AS year,
    pm.post_count,
    pm.avg_score,
    pm.total_views,
    pm.total_favorites,
    pm.total_answers,
    cm.comment_count,
    vm.vote_count,
    vm.upvote_count,
    vm.downvote_count,
    bm.badge_count,
    au.active_user_count
FROM post_metrics pm
FULL OUTER JOIN comment_metrics cm ON pm.year = cm.year
FULL OUTER JOIN vote_metrics vm ON COALESCE(pm.year, cm.year) = vm.year
FULL OUTER JOIN badge_metrics bm ON COALESCE(pm.year, cm.year, vm.year) = bm.year
FULL OUTER JOIN active_user_metrics au ON COALESCE(pm.year, cm.year, vm.year, bm.year) = au.year
ORDER BY year
