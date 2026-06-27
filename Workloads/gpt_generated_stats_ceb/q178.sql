WITH
    user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS owned_posts
        FROM posts
        GROUP BY owneruserid
    ),
    user_edited_posts AS (
        SELECT lasteditoruserid AS user_id,
               COUNT(*) AS edited_posts
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT userid AS user_id,
               COUNT(*) AS comments_made,
               COALESCE(SUM(score), 0) AS comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid AS user_id,
               COUNT(*) AS votes_cast,
               COALESCE(SUM(bountyamount), 0) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid AS user_id,
               COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT userid AS user_id,
               COUNT(*) AS post_history_entries
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS post_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tag_excerpts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS tag_excerpts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.owned_posts, 0) AS owned_posts,
    COALESCE(uep.edited_posts, 0) AS edited_posts,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.comment_score, 0) AS comment_score,
    CASE WHEN COALESCE(uc.comments_made, 0) > 0 THEN COALESCE(uc.comment_score, 0) / COALESCE(uc.comments_made, 0) ELSE 0 END AS avg_comment_score,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    CASE WHEN COALESCE(uv.votes_cast, 0) > 0 THEN COALESCE(uv.total_bounty_given, 0) / COALESCE(uv.votes_cast, 0) ELSE 0 END AS avg_bounty_per_vote,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    COALESCE(uph.post_history_entries, 0) AS post_history_entries,
    COALESCE(upl.post_links, 0) AS post_links,
    COALESCE(ute.tag_excerpts, 0) AS tag_excerpts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edited_posts uep ON uep.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_postlinks upl ON upl.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
ORDER BY owned_posts DESC, comments_made DESC
LIMIT 100
