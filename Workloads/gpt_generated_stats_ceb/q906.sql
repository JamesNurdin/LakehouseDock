WITH
    votes_agg AS (
        SELECT
            votes.postid AS post_id,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes,
            SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes,
            SUM(votes.bountyamount) AS total_bounty,
            AVG(voters.reputation) AS avg_voter_reputation
        FROM votes
        JOIN users AS voters ON votes.userid = voters.id
        GROUP BY votes.postid
    ),
    posthistory_agg AS (
        SELECT
            posthistory.posthistorytypeid AS post_id,
            COUNT(*) AS posthistory_count,
            COUNT(DISTINCT posthistory.userid) AS distinct_editors,
            MAX(posthistory.creationdate) AS latest_history_date
        FROM posthistory
        GROUP BY posthistory.posthistorytypeid
    ),
    outgoing_links AS (
        SELECT
            postlinks.postid AS post_id,
            COUNT(*) AS outgoing_link_count
        FROM postlinks
        GROUP BY postlinks.postid
    ),
    incoming_links AS (
        SELECT
            postlinks.relatedpostid AS post_id,
            COUNT(*) AS incoming_link_count
        FROM postlinks
        GROUP BY postlinks.relatedpostid
    )
SELECT
    posts.id AS post_id,
    posts.posttypeid,
    posts.creationdate,
    posts.score,
    posts.viewcount,
    posts.answercount,
    posts.commentcount,
    posts.favoritecount,
    owner_user.reputation AS owner_reputation,
    editor_user.reputation AS last_editor_reputation,
    COALESCE(votes_agg.vote_count, 0) AS total_votes,
    COALESCE(votes_agg.up_votes, 0) AS up_votes,
    COALESCE(votes_agg.down_votes, 0) AS down_votes,
    COALESCE(votes_agg.total_bounty, 0) AS total_bounty,
    COALESCE(votes_agg.avg_voter_reputation, 0) AS avg_voter_reputation,
    COALESCE(posthistory_agg.posthistory_count, 0) AS edit_events,
    COALESCE(posthistory_agg.distinct_editors, 0) AS distinct_editors,
    posthistory_agg.latest_history_date,
    COALESCE(outgoing_links.outgoing_link_count, 0) AS outgoing_links,
    COALESCE(incoming_links.incoming_link_count, 0) AS incoming_links
FROM posts
LEFT JOIN users AS owner_user ON posts.owneruserid = owner_user.id
LEFT JOIN users AS editor_user ON posts.lasteditoruserid = editor_user.id
LEFT JOIN votes_agg ON posts.id = votes_agg.post_id
LEFT JOIN posthistory_agg ON posts.id = posthistory_agg.post_id
LEFT JOIN outgoing_links ON posts.id = outgoing_links.post_id
LEFT JOIN incoming_links ON posts.id = incoming_links.post_id
ORDER BY total_votes DESC
LIMIT 10
