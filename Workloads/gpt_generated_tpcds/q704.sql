WITH catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        r.r_reason_desc,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        r.r_reason_desc,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
)
SELECT
    year,
    month_seq,
    category,
    state,
    reason,
    SUM(catalog_net_loss) AS total_catalog_net_loss,
    SUM(web_net_loss) AS total_web_net_loss,
    SUM(catalog_net_loss) + SUM(web_net_loss) AS total_net_loss
FROM (
    SELECT
        d_year AS year,
        d_month_seq AS month_seq,
        i_category AS category,
        ca_state AS state,
        r_reason_desc AS reason,
        cr_net_loss AS catalog_net_loss,
        CAST(0 AS decimal(7,2)) AS web_net_loss
    FROM catalog_returns_agg
    UNION ALL
    SELECT
        d_year AS year,
        d_month_seq AS month_seq,
        i_category AS category,
        ca_state AS state,
        r_reason_desc AS reason,
        CAST(0 AS decimal(7,2)) AS catalog_net_loss,
        wr_net_loss AS web_net_loss
    FROM web_returns_agg
) combined
GROUP BY year, month_seq, category, state, reason
ORDER BY total_net_loss DESC
LIMIT 100
