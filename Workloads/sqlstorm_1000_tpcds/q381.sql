WITH
store_sales_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(ss.ss_net_profit) AS sales_profit,
        COUNT(*) AS orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(sr.sr_net_loss) AS return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_sales_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(cs.cs_net_profit) AS sales_profit,
        COUNT(*) AS orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(cr.cr_net_loss) AS return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(ws.ws_net_profit) AS sales_profit,
        COUNT(*) AS orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
 SELECT d.d_year AS year, d.d_month_seq AS month, i.i_category AS category,
        SUM(wr.wr_net_loss) AS return_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
 SELECT s.year,
        s.month,
        s.category,
        (s.sales_profit - COALESCE(sr.return_loss, 0)) AS profit,
        s.orders,
        'store' AS channel
 FROM store_sales_agg s
 LEFT JOIN store_returns_agg sr ON s.year = sr.year AND s.month = sr.month AND s.category = sr.category
 UNION ALL
 SELECT c.year,
        c.month,
        c.category,
        (c.sales_profit - COALESCE(cr.return_loss, 0)) AS profit,
        c.orders,
        'catalog' AS channel
 FROM catalog_sales_agg c
 LEFT JOIN catalog_returns_agg cr ON c.year = cr.year AND c.month = cr.month AND c.category = cr.category
 UNION ALL
 SELECT w.year,
        w.month,
        w.category,
        (w.sales_profit - COALESCE(wr.return_loss, 0)) AS profit,
        w.orders,
        'web' AS channel
 FROM web_sales_agg w
 LEFT JOIN web_returns_agg wr ON w.year = wr.year AND w.month = wr.month AND w.category = wr.category
)
SELECT
    year,
    month,
    category,
    SUM(profit) AS total_profit,
    SUM(orders) AS total_orders,
    ROUND(SUM(profit) / NULLIF(SUM(orders), 0), 2) AS profit_per_order,
    SUM(CASE WHEN channel = 'store' THEN profit ELSE 0 END) AS store_profit,
    SUM(CASE WHEN channel = 'catalog' THEN profit ELSE 0 END) AS catalog_profit,
    SUM(CASE WHEN channel = 'web' THEN profit ELSE 0 END) AS web_profit,
    RANK() OVER (PARTITION BY year, month ORDER BY SUM(profit) DESC) AS category_rank,
    SUM(profit) - LAG(SUM(profit)) OVER (PARTITION BY category ORDER BY year, month) AS mom_profit_change
FROM combined
GROUP BY year, month, category
HAVING SUM(profit) > 0
ORDER BY year, month, total_profit DESC
