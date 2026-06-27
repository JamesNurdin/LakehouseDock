WITH vote_counts AS (
    SELECT
        votes.postid AS postid,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(votes.bountyamount) AS total_bounty,
        COUNT(DISTINCT votes.userid) AS distinct_voter_count
    FROM votes
    GROUP BY votes.postid
),

voter_reputation AS (
    SELECT
        votes.postid AS postid,
        AVG(users.reputation) AS avg_voter_reputation,
        MAX(users.reputation) AS max_voter_reputation,
        MIN(users.reputation) AS min_voter_reputation
    FROM votes
    JOIN users ON votes.userid = users.id
    GROUP BY votes.postid
)
SELECT
    posts.id,
    posts.posttypeid,
    posts.creationdate,
    posts.score,
    posts.viewcount,
    posts.answercount,
    posts.commentcount,
    posts.favoritecount,
    owner_user.reputation AS owner_reputation,
    editor_user.reputation AS editor_reputation,
    vote_counts.total_votes,
    vote_counts.upvote_count,
    vote_counts.downvote_count,
    vote_counts.total_bounty,
    vote_counts.distinct_voter_count,
    voter_reputation.avg_voter_reputation,
    voter_reputation.max_voter_reputation,
    voter_reputation.min_voter_reputation
FROM posts
LEFT JOIN users AS owner_user
    ON posts.owneruserid = owner_user.id
LEFT JOIN users AS editor_user
    ON posts.lasteditoruserid = editor_user.id
LEFT JOIN vote_counts
    ON posts.id = vote_counts.postid
LEFT JOIN voter_reputation
    ON posts.id = voter_reputation.postid
ORDER BY vote_counts.total_votes DESC
LIMIT 10
