WITH cs_agg AS (
   SELECT cs_item_sk,
          cs_ship_mode_sk,
          cs_warehouse_sk,
          cs_catalog_page_sk,
          cs_sold_time_sk,
          cs_order_number,
          SUM(cs_quantity)         AS total_quantity,
          SUM(cs_net_profit)       AS total_net_profit
   FROM catalog_sales
   GROUP BY cs_item_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_catalog_page_sk, cs_sold_time_sk, cs_order_number
),
ws_agg AS (
   SELECT ws_item_sk,
          ws_ship_mode_sk,
          ws_warehouse_sk,
          ws_web_site_sk,
          ws_sold_time_sk,
          SUM(ws_quantity)    AS ws_total_quantity,
          SUM(ws_net_profit)  AS ws_total_net_profit
   FROM web_sales
   GROUP BY ws_item_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_web_site_sk, ws_sold_time_sk
)
SELECT
   cp.cp_type,
   sm_cs.sm_type               AS ship_mode_type,
   t_sold.t_hour               AS sales_hour,
   SUM(cs_agg.total_quantity) AS catalog_quantity,
   SUM(cs_agg.total_net_profit) AS catalog_net_profit,
   SUM(cr.cr_return_quantity)    AS return_quantity,
   SUM(cr.cr_net_loss)           AS total_return_loss,
   SUM(ws_agg.ws_total_quantity) AS web_quantity,
   SUM(ws_agg.ws_total_net_profit) AS web_net_profit,
   COUNT(DISTINCT cs_agg.cs_order_number) AS distinct_orders
FROM cs_agg
JOIN catalog_page cp               ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs               ON cs_agg.cs_ship_mode_sk   = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs               ON cs_agg.cs_warehouse_sk  = w_cs.w_warehouse_sk
JOIN time_dim t_sold               ON cs_agg.cs_sold_time_sk  = t_sold.t_time_sk
LEFT JOIN catalog_returns cr        ON cr.cr_order_number      = cs_agg.cs_order_number
LEFT JOIN item i_return             ON cr.cr_item_sk           = i_return.i_item_sk
LEFT JOIN ship_mode sm_cr           ON cr.cr_ship_mode_sk      = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr            ON cr.cr_warehouse_sk      = w_cr.w_warehouse_sk
LEFT JOIN time_dim t_return         ON cr.cr_returned_time_sk  = t_return.t_time_sk
LEFT JOIN catalog_page cp2          ON cr.cr_catalog_page_sk   = cp2.cp_catalog_page_sk
LEFT JOIN item i_sales              ON cs_agg.cs_item_sk       = i_sales.i_item_sk
LEFT JOIN ws_agg                    ON ws_agg.ws_item_sk       = cs_agg.cs_item_sk
                                    AND ws_agg.ws_ship_mode_sk = cs_agg.cs_ship_mode_sk
                                    AND ws_agg.ws_warehouse_sk = cs_agg.cs_warehouse_sk
                                    AND ws_agg.ws_sold_time_sk = cs_agg.cs_sold_time_sk
LEFT JOIN web_site ws_site           ON ws_agg.ws_web_site_sk    = ws_site.web_site_sk
LEFT JOIN ship_mode sm_ws            ON ws_agg.ws_ship_mode_sk   = sm_ws.sm_ship_mode_sk
LEFT JOIN warehouse w_ws            ON ws_agg.ws_warehouse_sk   = w_ws.w_warehouse_sk
LEFT JOIN time_dim t_ws              ON ws_agg.ws_sold_time_sk   = t_ws.t_time_sk
WHERE cp.cp_type = 'quarterly'
GROUP BY cp.cp_type, sm_cs.sm_type, t_sold.t_hour
ORDER BY catalog_net_profit DESC
LIMIT 100
