WITH cs_agg AS (
    SELECT i.i_category AS category,
           sm.sm_ship_mode_id AS ship_mode,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_ext_discount_amt) AS total_discount,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, sm.sm_ship_mode_id
),
ws_agg AS (
    SELECT i.i_category AS category,
           sm.sm_ship_mode_id AS ship_mode,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, sm.sm_ship_mode_id
),
cr_agg AS (
    SELECT i.i_category AS category,
           sm.sm_ship_mode_id AS ship_mode,
           SUM(cr.cr_return_quantity) AS total_quantity,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, sm.sm_ship_mode_id
)
SELECT COALESCE(cs.category, ws.category, cr.category) AS category,
       COALESCE(cs.ship_mode, ws.ship_mode, cr.ship_mode) AS ship_mode,
       COALESCE(cs.total_quantity, 0) + COALESCE(ws.total_quantity, 0) AS total_quantity,
       COALESCE(cs.total_net_profit, 0) + COALESCE(ws.total_net_profit, 0) - COALESCE(cr.total_net_loss, 0) AS net_profit_after_returns,
       COALESCE(cs.total_discount, 0) + COALESCE(ws.total_discount, 0) AS total_discount,
       COALESCE(cs.distinct_customers, 0) + COALESCE(ws.distinct_customers, 0) AS distinct_customers
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
  ON cs.category = ws.category
 AND cs.ship_mode = ws.ship_mode
FULL OUTER JOIN cr_agg cr
  ON COALESCE(cs.category, ws.category) = cr.category
 AND COALESCE(cs.ship_mode, ws.ship_mode) = cr.ship_mode
ORDER BY net_profit_after_returns DESC
LIMIT 20
