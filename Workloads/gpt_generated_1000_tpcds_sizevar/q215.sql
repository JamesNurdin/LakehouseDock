WITH
  -- Aggregate inventory per item and warehouse
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  -- Scalar sub‑query used in a comparison predicate
  max_summer_cost AS (
    SELECT MAX(p_cost) AS cost_val
    FROM promotion
    WHERE p_promo_name = 'Summer Sale'
  ),
  -- Store side aggregation (includes store returns)
  store_part AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      CAST(NULL AS varchar) AS ship_mode_code,
      p.p_cost,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
      AVG(ss.ss_quantity) AS avg_qty,
      MAX(ss.ss_net_profit) AS max_profit,
      ia.total_qty,
      SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
      CAST(NULL AS decimal(7,2)) AS total_web_returns,
      w.w_warehouse_name
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN inv_agg ia ON ia.inv_item_sk = ss.ss_item_sk
    LEFT JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand = 'BrandX'
      AND ca.ca_state = 'CA'
      AND td.t_hour = 14
      AND p.p_cost > (SELECT cost_val FROM max_summer_cost)
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      p.p_cost,
      ia.total_qty,
      w.w_warehouse_name
  ),
  -- Web side aggregation (includes web returns)
  web_part AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      sm.sm_code AS ship_mode_code,
      p.p_cost,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
      AVG(ws.ws_quantity) AS avg_qty,
      MAX(ws.ws_net_profit) AS max_profit,
      ia.total_qty,
      CAST(NULL AS decimal(7,2)) AS total_returns,
      SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
      w.w_warehouse_name
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inv_agg ia ON ia.inv_item_sk = ws.ws_item_sk
    LEFT JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand = 'BrandX'
      AND ca.ca_state = 'CA'
      AND sm.sm_code = 'AIR'
      AND td.t_hour = 14
      AND p.p_cost > (SELECT cost_val FROM max_summer_cost)
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      sm.sm_code,
      p.p_cost,
      ia.total_qty,
      w.w_warehouse_name
  ),
  -- Union of store and web aggregates
  union_agg AS (
    SELECT * FROM store_part
    UNION DISTINCT
    SELECT * FROM web_part
  ),
  -- Remove items that belong to an obsolete category
  cleaned_agg AS (
    SELECT * FROM union_agg
    EXCEPT
    SELECT * FROM union_agg WHERE i_item_id IN (SELECT i_item_id FROM item WHERE i_category = 'Obsolete')
  ),
  -- Expand an array of metrics per item
  exploded AS (
    SELECT
      i_item_id,
      ship_mode_code,
      total_sales,
      order_cnt,
      avg_qty,
      max_profit,
      total_qty,
      total_returns,
      total_web_returns,
      w_warehouse_name,
      ARRAY[total_sales, avg_qty] AS metrics
    FROM cleaned_agg
  )
SELECT
  i_item_id,
  ship_mode_code,
  metric
FROM exploded
CROSS JOIN UNNEST(metrics) AS t(metric)
ORDER BY i_item_id
LIMIT 100
