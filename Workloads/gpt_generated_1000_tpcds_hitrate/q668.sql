WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS ss_qty,
        SUM(ss_net_paid) AS ss_net_paid,
        SUM(ss_net_profit) AS ss_profit
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk, ss_sold_date_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS ws_qty,
        SUM(ws_net_paid) AS ws_net_paid,
        SUM(ws_net_profit) AS ws_profit
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk, ws_sold_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    SUM(COALESCE(ss_agg.ss_qty, 0)) AS store_qty,
    SUM(COALESCE(ws_agg.ws_qty, 0)) AS web_qty,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS store_return_qty,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS web_return_qty,
    AVG(CASE WHEN sr.sr_return_amt IS NOT NULL THEN sr.sr_return_amt END) AS avg_store_return_amt,
    AVG(CASE WHEN wr.wr_return_amt IS NOT NULL THEN wr.wr_return_amt END) AS avg_web_return_amt
FROM date_dim d
JOIN ss_agg ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN ws_agg ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN item i ON i.i_item_sk = ss_agg.ss_item_sk
    AND i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = ss_agg.ss_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = ws_agg.ws_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1211
    AND d.d_dow IN (1, 2, 3)
    AND d.d_current_month = 'Y'
    AND i.i_brand = 'Brand#12'
    AND i.i_color = 'PINK'
    AND sr.sr_return_quantity > 0
    AND wr.wr_return_ship_cost > 100
    AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_amt > 200
    )
GROUP BY GROUPING SETS (
    (d.d_year, i.i_category, i.i_brand),
    (d.d_year, i.i_category),
    (d.d_year)
)
HAVING SUM(COALESCE(ss_agg.ss_qty, 0)) > 0
ORDER BY d.d_year DESC, i.i_category ASC
OFFSET 0 LIMIT 100
