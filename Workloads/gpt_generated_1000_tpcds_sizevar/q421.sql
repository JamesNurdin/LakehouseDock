WITH date_filter AS (
    SELECT d_date_sk, d_date
    FROM tpcds.date_dim
    WHERE d_year = 2001
)
SELECT
    d.d_date AS transaction_date,
    cs.cs_net_paid AS amount,
    'sale' AS txn_type,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    cc.cc_market_manager AS market_manager
FROM date_filter d
JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cs.cs_quantity > 0

UNION ALL

SELECT
    d.d_date AS transaction_date,
    cr.cr_net_loss * -1 AS amount,
    'return' AS txn_type,
    CASE WHEN cr.cr_net_loss < 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    cc.cc_market_manager AS market_manager
FROM date_filter d
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_order_number = cr.cr_order_number
      AND cs2.cs_net_profit > 0
)
ORDER BY transaction_date DESC
LIMIT 100
