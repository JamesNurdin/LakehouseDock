WITH combined_sales AS (
  SELECT d.d_year,
         d.d_month_seq,
         c.cc_name AS location_name,
         'catalog' AS channel,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_sales_price AS sales_amount,
         cs.cs_order_number AS order_number
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center c ON c.cc_call_center_sk = cs.cs_call_center_sk
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         s.s_store_name AS location_name,
         'store' AS channel,
         ss.ss_net_profit AS net_profit,
         ss.ss_ext_sales_price AS sales_amount,
         ss.ss_ticket_number AS order_number
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON s.s_store_sk = ss.ss_store_sk
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         w.w_warehouse_name AS location_name,
         'web' AS channel,
         ws.ws_net_profit AS net_profit,
         ws.ws_ext_sales_price AS sales_amount,
         ws.ws_order_number AS order_number
  FROM date_dim d
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
),
sales_agg AS (
  SELECT d_year,
         d_month_seq,
         channel,
         location_name,
         SUM(sales_amount) AS total_sales,
         SUM(net_profit) AS total_net_profit,
         COUNT(DISTINCT order_number) AS total_orders
  FROM combined_sales
  WHERE d_year = 2001
  GROUP BY d_year, d_month_seq, channel, location_name
),
returns_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         'catalog' AS channel,
         SUM(cr.cr_net_loss) AS total_net_loss
  FROM date_dim d
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         'store' AS channel,
         SUM(sr.sr_net_loss) AS total_net_loss
  FROM date_dim d
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         'web' AS channel,
         SUM(wr.wr_net_loss) AS total_net_loss
  FROM date_dim d
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
),
sales_with_returns AS (
  SELECT s.d_year,
         s.d_month_seq,
         s.channel,
         s.location_name,
         s.total_sales,
         s.total_net_profit,
         COALESCE(r.total_net_loss, 0) AS total_net_loss,
         s.total_sales - COALESCE(r.total_net_loss, 0) AS net_sales_adj
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.channel = r.channel
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
  FROM sales_with_returns
)
SELECT d_year,
       d_month_seq,
       channel,
       location_name,
       total_sales,
       total_net_profit,
       total_net_loss,
       net_sales_adj,
       sales_rank
FROM ranked
WHERE sales_rank <= 10
ORDER BY d_year, d_month_seq, sales_rank
