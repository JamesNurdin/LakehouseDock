WITH
store_sales_agg AS (
 SELECT d.d_year AS sales_year,
        s.s_state AS state,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        0.0 AS net_loss
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 GROUP BY d.d_year, s.s_state
),
store_returns_agg AS (
 SELECT d.d_year AS sales_year,
        s.s_state AS state,
        0.0 AS net_paid,
        0.0 AS net_profit,
        SUM(sr.sr_net_loss) AS net_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 GROUP BY d.d_year, s.s_state
),
catalog_sales_agg AS (
 SELECT d.d_year AS sales_year,
        w.w_state AS state,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        0.0 AS net_loss
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
 GROUP BY d.d_year, w.w_state
),
catalog_returns_agg AS (
 SELECT d.d_year AS sales_year,
        w.w_state AS state,
        0.0 AS net_paid,
        0.0 AS net_profit,
        SUM(cr.cr_net_loss) AS net_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
 GROUP BY d.d_year, w.w_state
),
web_sales_agg AS (
 SELECT d.d_year AS sales_year,
        w.w_state AS state,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        0.0 AS net_loss
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
 GROUP BY d.d_year, w.w_state
),
web_returns_agg AS (
 SELECT d.d_year AS sales_year,
        w.w_state AS state,
        0.0 AS net_paid,
        0.0 AS net_profit,
        SUM(wr.wr_net_loss) AS net_loss
 FROM web_returns wr
 JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
 GROUP BY d.d_year, w.w_state
),
combined AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM store_returns_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM catalog_returns_agg
 UNION ALL
 SELECT * FROM web_sales_agg
 UNION ALL
 SELECT * FROM web_returns_agg
)
SELECT
 sales_year,
 state,
 SUM(net_paid) AS total_net_paid,
 SUM(net_profit) AS total_net_profit,
 SUM(net_loss) AS total_net_loss,
 SUM(net_paid) - SUM(net_loss) AS net_revenue
FROM combined
GROUP BY sales_year, state
ORDER BY sales_year, state
LIMIT 100
