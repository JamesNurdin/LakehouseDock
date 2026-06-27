WITH all_returns AS (
    SELECT 
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        sr.sr_net_loss AS net_loss,
        ca.ca_state
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT 
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        cr.cr_net_loss AS net_loss,
        ca.ca_state
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT 
        d.d_year,
        d.d_moy,
        r.r_reason_desc,
        wr.wr_net_loss AS net_loss,
        ca.ca_state
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT 
    ca_state AS state,
    r_reason_desc AS reason,
    d_year AS year,
    d_moy AS month,
    SUM(net_loss) AS total_net_loss
FROM all_returns
GROUP BY ca_state, r_reason_desc, d_year, d_moy
ORDER BY total_net_loss DESC
LIMIT 50
