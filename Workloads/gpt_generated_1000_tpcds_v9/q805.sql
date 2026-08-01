SELECT
    ca.ca_state AS state,
    r.r_reason_desc AS reason,
    SUM(sr.sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(sr.sr_net_loss) > (
            SELECT AVG(net_loss) FROM (
                SELECT sr2.sr_net_loss AS net_loss FROM store_returns sr2
                UNION ALL
                SELECT wr2.wr_net_loss AS net_loss FROM web_returns wr2
            ) AS all_ret
        ) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY ca.ca_state, r.r_reason_desc

UNION ALL

SELECT
    ca.ca_state AS state,
    r.r_reason_desc AS reason,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr.wr_net_loss) > (
            SELECT AVG(net_loss) FROM (
                SELECT sr2.sr_net_loss AS net_loss FROM store_returns sr2
                UNION ALL
                SELECT wr2.wr_net_loss AS net_loss FROM web_returns wr2
            ) AS all_ret
        ) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM web_returns wr
JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY ca.ca_state, r.r_reason_desc

ORDER BY total_net_loss DESC
LIMIT 100
