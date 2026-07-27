WITH catalog_rev AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS total_revenue,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'MO'
      AND cs.cs_ext_sales_price > 500
    GROUP BY cs.cs_item_sk
),
web_rev AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'MO'
      AND ws.ws_ext_sales_price > 500
    GROUP BY ws.ws_item_sk
),
combined AS (
    SELECT item_sk, total_revenue, sales_cnt, 'catalog' AS channel FROM catalog_rev
    UNION ALL
    SELECT item_sk, total_revenue, sales_cnt, 'web' AS channel FROM web_rev
),
item_avg_price AS (
    SELECT i_item_sk, AVG(i_current_price) AS avg_price
    FROM item
    GROUP BY i_item_sk
)
SELECT
    c.item_sk,
    i.i_product_name,
    c.channel,
    c.total_revenue,
    c.sales_cnt,
    ip.avg_price,
    RANK() OVER (PARTITION BY c.channel ORDER BY c.total_revenue DESC) AS revenue_rank
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
LEFT JOIN item_avg_price ip ON c.item_sk = ip.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN item wi ON wr.wr_item_sk = wi.i_item_sk
    WHERE wi.i_item_sk = c.item_sk
      AND wr.wr_return_amt > 0
)
ORDER BY c.channel, revenue_rank
LIMIT 100
