-- Analytical query: count of post‑history events per post owner and post type
SELECT
    posts.owneruserid,
    posts.posttypeid,
    COUNT(posthistory.id) AS history_count,
    SUM(posts.score) AS total_score,
    AVG(posts.viewcount) AS avg_viewcount,
    MAX(posthistory.creationdate) AS latest_history_date,
    MIN(posthistory.creationdate) AS earliest_history_date
FROM posthistory
JOIN posts
  ON posthistory.posthistorytypeid = posts.id
GROUP BY posts.owneruserid, posts.posttypeid
ORDER BY history_count DESC
LIMIT 20
