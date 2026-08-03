WITH sub1 AS (
    SELECT
        ca.ca_state,
        r.r_reason_desc,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        CASE WHEN SUM(COALESCE(sr.sr_net_loss, 0)) > 1000 THEN 'high' ELSE 'low' END AS loss_category
    FROM store_returns sr
    FULL OUTER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_fee > 30
    GROUP BY ca.ca_state, r.r_reason_desc
),
sub2 AS (
    SELECT
        ca.ca_state,
        r.r_reason_desc,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        CASE WHEN SUM(COALESCE(sr.sr_net_loss, 0)) > 500 THEN 'high' ELSE 'low' END AS loss_category
    FROM store_returns sr
    FULL OUTER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_reversed_charge < 200
    GROUP BY ca.ca_state, r.r_reason_desc
)
SELECT
    u.ca_state,
    u.r_reason_desc,
    u.total_net_loss,
    u.loss_category,
    ROW_NUMBER() OVER (ORDER BY u.total_net_loss DESC) AS global_row_num
FROM (
    SELECT ca_state, r_reason_desc, total_net_loss, loss_category FROM sub1
    UNION ALL
    SELECT ca_state, r_reason_desc, total_net_loss, loss_category FROM sub2
) AS u
ORDER BY u.total_net_loss DESC, u.ca_state
