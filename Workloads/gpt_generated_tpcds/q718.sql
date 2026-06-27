WITH returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        ca.ca_state,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        ca.ca_state,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        ca.ca_state,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    ca_state,
    SUM(CASE WHEN channel = 'store'   THEN net_loss ELSE 0 END) AS store_net_loss,
    SUM(CASE WHEN channel = 'catalog' THEN net_loss ELSE 0 END) AS catalog_net_loss,
    SUM(CASE WHEN channel = 'web'     THEN net_loss ELSE 0 END) AS web_net_loss,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(net_loss) AS avg_net_loss_per_return
FROM returns
WHERE d_year = 2001
GROUP BY d_year, d_month_seq, r_reason_desc, ca_state
ORDER BY total_net_loss DESC
LIMIT 100
