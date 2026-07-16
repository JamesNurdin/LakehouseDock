WITH returns_agg AS (
   SELECT cr_returned_date_sk AS date_sk,
          COALESCE(SUM(cr_net_loss), 0) AS total_return_loss
   FROM catalog_returns
   GROUP BY cr_returned_date_sk
), web_sales_agg AS (
   SELECT ws.ws_sold_date_sk AS date_sk,
          COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
          COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
          COUNT(DISTINCT ws.ws_order_number) AS web_orders,
          COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_web_discount,
          COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
          SUM(CASE WHEN d_ws_ship.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_shipment_count
   FROM web_sales ws
   JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
   GROUP BY ws.ws_sold_date_sk
), store_sales_agg AS (
   SELECT ss.ss_store_sk,
          ss.ss_sold_date_sk,
          COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
          COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
          COALESCE(SUM(ss.ss_ext_discount_amt), 0) AS total_store_discount,
          COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
          COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
   FROM store_sales ss
   GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_moy AS month,
    ss_agg.total_store_sales,
    ss_agg.total_store_profit,
    ws_agg.total_web_sales,
    ws_agg.total_web_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    ss_agg.store_tickets,
    ws_agg.web_orders,
    ws_agg.weekend_shipment_count,
    CASE WHEN ss_agg.total_store_quantity > 0
         THEN ss_agg.total_store_discount / ss_agg.total_store_quantity
         ELSE NULL END AS avg_store_discount_per_qty,
    CASE WHEN ws_agg.total_web_quantity > 0
         THEN ws_agg.total_web_discount / ws_agg.total_web_quantity
         ELSE NULL END AS avg_web_discount_per_qty,
    CASE WHEN ss_agg.total_store_sales > 0
         THEN COALESCE(ra.total_return_loss, 0) / ss_agg.total_store_sales
         ELSE NULL END AS return_to_sales_ratio,
    ss_agg.total_store_profit - ws_agg.total_web_profit AS profit_difference,
    CASE WHEN d_store_closed.d_date IS NOT NULL THEN 1 ELSE 0 END AS store_closed_flag
FROM store_sales_agg ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN returns_agg ra ON ra.date_sk = d_sales.d_date_sk
LEFT JOIN web_sales_agg ws_agg ON ws_agg.date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sales.d_year = 2023
ORDER BY d_sales.d_year, d_sales.d_moy, s.s_store_id
