WITH cs_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           i.i_category AS category,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt,
           CAST(NULL AS decimal(7,2)) AS avg_return_amt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
    GROUP BY cs.cs_item_sk, i.i_category
),
ws_sales AS (
    SELECT ws.ws_item_sk AS item_sk,
           i.i_category AS category,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt,
           (
               SELECT AVG(wr.wr_return_amt)
               FROM web_returns wr
               WHERE wr.wr_item_sk = ws.ws_item_sk
           ) AS avg_return_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 3000
    GROUP BY ws.ws_item_sk, i.i_category
),
combined AS (
    SELECT * FROM cs_sales
    UNION ALL
    SELECT * FROM ws_sales
)
SELECT combined.item_sk,
       combined.category,
       combined.total_profit,
       combined.sales_cnt,
       combined.avg_return_amt,
       CASE
           WHEN combined.total_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg Profit'
           ELSE 'Below Avg Profit'
       END AS profit_category
FROM combined
WHERE EXISTS (
    SELECT 1
    FROM item i
    WHERE i.i_item_sk = combined.item_sk
      AND i.i_color = 'Unknown'
)
ORDER BY combined.total_profit DESC
LIMIT 100
