WITH
  -- Union of catalog_sales and web_sales (deduplicated)
  union_sales AS (
    SELECT
      cs.cs_item_sk               AS item_sk,
      cs.cs_sold_time_sk          AS time_sk,
      cs.cs_quantity              AS quantity,
      cs.cs_net_paid              AS net_paid,
      cs.cs_call_center_sk        AS call_center_sk,
      cs.cs_ship_mode_sk          AS ship_mode_sk,
      cs.cs_warehouse_sk          AS warehouse_sk,
      cs.cs_promo_sk              AS promo_sk,
      cs.cs_order_number          AS order_number,
      cs.cs_bill_addr_sk          AS address_sk,
      cs.cs_bill_cdemo_sk         AS demo_sk,
      NULL                        AS web_page_sk,
      NULL                        AS web_site_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
    UNION DISTINCT
    SELECT
      ws.ws_item_sk               AS item_sk,
      ws.ws_sold_time_sk          AS time_sk,
      ws.ws_quantity              AS quantity,
      ws.ws_net_paid              AS net_paid,
      NULL                        AS call_center_sk,
      ws.ws_ship_mode_sk          AS ship_mode_sk,
      ws.ws_warehouse_sk          AS warehouse_sk,
      ws.ws_promo_sk              AS promo_sk,
      ws.ws_order_number          AS order_number,
      ws.ws_bill_addr_sk          AS address_sk,
      ws.ws_bill_cdemo_sk         AS demo_sk,
      ws.ws_web_page_sk           AS web_page_sk,
      ws.ws_web_site_sk           AS web_site_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
      AND ws.ws_net_paid > 100
  ),

  -- Intersection of item‑time keys that appear both in store_returns and web_sales
  intersect_keys AS (
    SELECT sr.sr_item_sk AS item_sk, sr.sr_return_time_sk AS time_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    INTERSECT
    SELECT ws.ws_item_sk, ws.ws_sold_time_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
  ),

  -- Main joined dataset bringing in all dimension tables
  joined AS (
    SELECT
      us.item_sk,
      us.time_sk,
      us.quantity,
      us.net_paid,
      us.call_center_sk,
      us.ship_mode_sk,
      us.warehouse_sk,
      us.promo_sk,
      us.order_number,
      us.address_sk,
      us.demo_sk,
      us.web_page_sk,
      us.web_site_sk,
      i.i_category,
      i.i_brand,
      cc.cc_state,
      p.p_discount_active,
      sm.sm_type,
      w.w_warehouse_name,
      ca.ca_state AS address_state,
      cd.cd_gender,
      td.t_hour,
      wp.wp_type,
      wsit.web_name,
      -- Correlated scalar sub‑query: total return amount for the same item
      (SELECT SUM(sr_return_amt)
       FROM store_returns sr
       WHERE sr.sr_item_sk = us.item_sk) AS total_return_amt,
      -- Build a 2‑element array and explode it
      ARRAY[us.quantity, us.net_paid] AS qty_net_arr
    FROM union_sales us
    JOIN item i               ON us.item_sk = i.i_item_sk
    JOIN time_dim td          ON us.time_sk = td.t_time_sk
    LEFT JOIN promotion p     ON us.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc  ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm    ON us.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w     ON us.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_address ca ON us.address_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON us.demo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp     ON us.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit   ON us.web_site_sk = wsit.web_site_sk
  ),

  -- Expand the array created per row
  expanded AS (
    SELECT
      j.*,
      unnested.value AS array_val,
      CASE WHEN unnested.ordinality = 1 THEN 'quantity' ELSE 'net_paid' END AS array_element
    FROM joined j
    CROSS JOIN UNNEST(j.qty_net_arr) WITH ORDINALITY AS unnested(value, ordinality)
  )

SELECT
  e.i_category,
  e.cc_state,
  SUM(e.quantity)               AS total_quantity,
  AVG(e.net_paid)               AS avg_net_paid,
  COUNT(*)                       AS rows_cnt,
  MIN(e.total_return_amt)       AS min_total_return_amt,
  MAX(e.total_return_amt)       AS max_total_return_amt,
  COUNT(DISTINCT e.item_sk)      AS distinct_items,
  -- Example of picking a value from the expanded array (just for demonstration)
  MAX(CASE WHEN e.array_element = 'quantity' THEN e.array_val END) AS max_quantity_in_array,
  MAX(CASE WHEN e.array_element = 'net_paid' THEN e.array_val END) AS max_net_paid_in_array
FROM expanded e
WHERE e.t_hour BETWEEN 8 AND 18                     -- filter on hour of day
  AND e.i_category IN ('Books', 'Electronics')      -- filter on category
  AND e.cc_state = 'CA'                             -- filter on call center state
  AND e.p_discount_active = 'Y'                     -- filter on promotion flag
  AND e.sm_type = 'AIR'                             -- filter on ship mode type
GROUP BY GROUPING SETS (
    (e.i_category, e.cc_state),
    (e.i_category),
    ()
)
ORDER BY total_quantity DESC
LIMIT 100
