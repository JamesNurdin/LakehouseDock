SELECT
    date_trunc('month', p.creationdate) AS month,
    COUNT(p.id) AS num_posts,
    SUM(p.score) AS total_post_score,
    AVG(p.score) AS avg_post_score,
    SUM(p.commentcount) AS total_comments,
    COUNT(v.id) AS total_votes,
    1.0 * SUM(p.commentcount) / nullif(COUNT(v.id), 0) AS comment_to_vote_ratio,
    COUNT(DISTINCT c.userid) AS distinct_commenters,
    COUNT(DISTINCT v.userid) AS distinct_voters,
    AVG(u.reputation) AS avg_owner_reputation,
    COUNT(t.id) AS num_tags,
    COUNT(l.id) AS num_post_links,
    COUNT(h.id) AS num_post_history,
    1.0 * COUNT(t.id) / nullif(COUNT(p.id), 0) AS avg_tags_per_post,
    1.0 * COUNT(l.id) / nullif(COUNT(p.id), 0) AS avg_links_per_post,
    1.0 * COUNT(h.id) / nullif(COUNT(p.id), 0) AS avg_history_events_per_post
FROM posts p
LEFT JOIN users u ON p.owneruserid = u.id
LEFT JOIN comments c ON c.postid = p.id
LEFT JOIN votes v ON v.postid = p.id
LEFT JOIN tags t ON t.excerptpostid = p.id
LEFT JOIN postlinks l ON l.postid = p.id
LEFT JOIN posthistory h ON h.posthistorytypeid = p.id
WHERE p.creationdate >= TIMESTAMP '2022-01-01 00:00:00 UTC'
  AND p.creationdate < TIMESTAMP '2023-01-01 00:00:00 UTC'
GROUP BY date_trunc('month', p.creationdate)
ORDER BY date_trunc('month', p.creationdate)
