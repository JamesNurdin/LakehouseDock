WITH sales_with_returns AS (
   SELECT
      s.s_store_id,
      s.s_manager,
      dd.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
      COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
      MIN(ws.ws_wholesale_cost) AS min_wholesale_cost,
      MAX(ws.ws_wholesale_cost) AS max_wholesale_cost,
      s.s_hours
   FROM web_sales ws
   JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
   JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
   JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
   JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2001
     AND ws.ws_wholesale_cost > 50
     AND s.s_manager = 'Wayne Coleman'
     AND s.s_hours LIKE '%8AM-8AM%'
     AND wr.wr_return_amt_inc_tax > 30
     AND EXISTS (
         SELECT 1 FROM inventory inv
         WHERE inv.inv_date_sk = dd.d_date_sk
           AND inv.inv_quantity_on_hand > 100
     )
   GROUP BY s.s_store_id, s.s_manager, dd.d_year, s.s_hours
),
sales_without_returns AS (
   SELECT
      s.s_store_id,
      s.s_manager,
      dd.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      CAST(0 AS decimal(7,2)) AS total_return_amount,
      COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
      MIN(ws.ws_wholesale_cost) AS min_wholesale_cost,
      MAX(ws.ws_wholesale_cost) AS max_wholesale_cost,
      s.s_hours
   FROM web_sales ws
   JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
   JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2001
     AND ws.ws_wholesale_cost > 50
     AND s.s_manager = 'Wayne Coleman'
     AND s.s_hours LIKE '%8AM-8AM%'
     AND wr.wr_returned_date_sk IS NULL
     AND EXISTS (
         SELECT 1 FROM inventory inv
         WHERE inv.inv_date_sk = dd.d_date_sk
           AND inv.inv_quantity_on_hand > 100
     )
   GROUP BY s.s_store_id, s.s_manager, dd.d_year, s.s_hours
),
union_sales AS (
   SELECT
      s_store_id,
      s_manager,
      d_year,
      total_sales,
      total_profit,
      total_return_amount,
      distinct_items,
      min_wholesale_cost,
      max_wholesale_cost,
      s_hours
   FROM sales_with_returns
   UNION ALL
   SELECT
      s_store_id,
      s_manager,
      d_year,
      total_sales,
      total_profit,
      total_return_amount,
      distinct_items,
      min_wholesale_cost,
      max_wholesale_cost,
      s_hours
   FROM sales_without_returns
)
SELECT
   us.s_store_id,
   us.s_manager,
   us.d_year,
   us.total_sales,
   us.total_profit,
   us.total_return_amount,
   us.distinct_items,
   us.min_wholesale_cost,
   us.max_wholesale_cost,
   hour_part
FROM union_sales us
CROSS JOIN UNNEST(split(us.s_hours, '-')) AS t (hour_part)
WHERE us.total_sales > 1000
  AND us.total_profit > 0
ORDER BY us.total_sales DESC
LIMIT 100
