WITH ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sales_price > 50
    GROUP BY ws_sold_date_sk, ws_item_sk
)
SELECT
    d.d_date,
    cr.cr_return_amount,
    sr.sr_fee,
    ws_agg.total_sales,
    ws_agg.total_profit,
    CASE
        WHEN ws_agg.total_profit > 10000 THEN 'High'
        WHEN ws_agg.total_profit > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ws_agg.total_profit DESC) AS profit_rank_year
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN ws_agg
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  AND cr.cr_return_amount > 1000
  AND sr.sr_fee < 50
ORDER BY profit_rank_year
LIMIT 100
