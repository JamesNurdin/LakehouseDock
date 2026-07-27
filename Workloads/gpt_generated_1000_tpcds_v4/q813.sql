/*
Goal: Compare total net paid sales versus total returned amounts per web site for the year 2020, labeling each transaction type and indicating whether the net amount is positive or not.
*/
WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        d.d_year,
        ws.ws_net_paid AS amount,
        'sale' AS trans_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
returns_agg AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        d.d_year,
        wr.wr_return_amt AS amount,
        'return' AS trans_type
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
)
SELECT
    w.web_name AS web_site_name,
    agg.d_year,
    agg.trans_type,
    SUM(agg.amount) AS total_amount,
    CASE WHEN SUM(agg.amount) > 0 THEN 'Positive' ELSE 'Non-positive' END AS amount_sign
FROM (
    SELECT web_site_sk, d_year, trans_type, amount FROM sales_agg
    UNION ALL
    SELECT web_site_sk, d_year, trans_type, amount FROM returns_agg
) agg
JOIN web_site w ON agg.web_site_sk = w.web_site_sk
GROUP BY w.web_name, agg.d_year, agg.trans_type
ORDER BY total_amount DESC
LIMIT 100
