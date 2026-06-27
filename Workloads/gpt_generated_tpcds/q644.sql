WITH returns_by_state_reason_month AS (
    SELECT
        ca.ca_state AS state,
        r.r_reason_desc AS reason,
        date_trunc('month', d.d_date) AS month,
        COUNT(*) AS returns_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
    GROUP BY ca.ca_state, r.r_reason_desc, date_trunc('month', d.d_date)
)
SELECT
    state,
    reason,
    month,
    returns_cnt,
    total_net_loss,
    avg_return_amount,
    RANK() OVER (PARTITION BY state ORDER BY total_net_loss DESC) AS reason_rank_by_loss
FROM returns_by_state_reason_month
ORDER BY state, total_net_loss DESC
