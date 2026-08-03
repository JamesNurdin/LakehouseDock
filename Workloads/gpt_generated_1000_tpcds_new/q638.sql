/*
Goal: Compute per‑item sales performance across store and web channels for the year 2001, filtered to a specific brand and California locations, enriched with latest promotion name, current inventory, and return information. The query demonstrates complex joins of all 14 TPC‑DS tables, uses TABLESAMPLE, UNNEST, LATERAL sub‑query, scalar sub‑query, UNION, CTE aggregation, additional filters, ordering and pagination.
*/
WITH
  -- Sampled Store Sales with required joins and filters
  store_sales_sample AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      d.d_year,
      i.i_category,
      s.s_state,
      p.p_channel_dmail,
      ARRAY[ss.ss_quantity, ss.ss_ext_sales_price] AS metrics_array
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)   -- 10 % random sample
    JOIN date_dim d       ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t       ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i           ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer c       ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk    = ca.ca_address_sk
    JOIN store s          ON ss.ss_store_sk       = s.s_store_sk
    JOIN promotion p      ON ss.ss_promo_sk       = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND p.p_channel_dmail = 'Y'
  ),

  -- Sampled Web Sales with required joins and filters
  web_sales_sample AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      NULL AS ss_store_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      d.d_year,
      i.i_category,
      w.w_state,
      p.p_channel_dmail,
      sm.sm_type,
      ARRAY[ws.ws_quantity, ws.ws_ext_sales_price] AS metrics_array
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)   -- 10 % random sample
    JOIN date_dim d       ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t       ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN item i           ON ws.ws_item_sk        = i.i_item_sk
    JOIN customer bc      ON ws.ws_bill_customer_sk = bc.c_customer_sk
    JOIN customer_demographics bcd ON ws.ws_bill_cdemo_sk = bcd.cd_demo_sk
    JOIN customer_address bca ON ws.ws_bill_addr_sk = bca.ca_address_sk
    JOIN ship_mode sm     ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w      ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion p      ON ws.ws_promo_sk       = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND p.p_channel_dmail = 'Y'
  ),

  -- Inventory information for the same period, brand and state
  inventory_info AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_warehouse_sk,
      inv.inv_quantity_on_hand,
      d.d_year,
      i.i_category,
      w.w_state
    FROM inventory inv
    JOIN date_dim d   ON inv.inv_date_sk    = d.d_date_sk
    JOIN item i       ON inv.inv_item_sk    = i.i_item_sk
    JOIN warehouse w  ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
  ),

  -- Returns information for the same period, brand and state
  returns_info AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_warehouse_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      d.d_year,
      i.i_category,
      w.w_state
    FROM catalog_returns cr
    JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t   ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i       ON cr.cr_item_sk        = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w  ON cr.cr_warehouse_sk   = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
  ),

  -- Union of store and web sales (distinct) with a metrics array
  sales_union AS (
    SELECT
      ss.ss_sold_date_sk   AS sold_date_sk,
      ss.ss_item_sk        AS item_sk,
      ss.ss_store_sk       AS store_sk,
      ss.ss_quantity       AS quantity,
      ss.ss_ext_sales_price AS ext_sales_price,
      ss.ss_net_profit     AS net_profit,
      ss.metrics_array,
      'store'               AS channel
    FROM store_sales_sample ss
    UNION DISTINCT
    SELECT
      ws.ws_sold_date_sk   AS sold_date_sk,
      ws.ws_item_sk        AS item_sk,
      ws.ss_store_sk       AS store_sk,
      ws.ws_quantity       AS quantity,
      ws.ws_ext_sales_price AS ext_sales_price,
      ws.ws_net_profit     AS net_profit,
      ws.metrics_array,
      'web'                AS channel
    FROM web_sales_sample ws
  ),

  -- Expand the array into separate rows (metric position = 1 → quantity, 2 → sales price)
  expanded_sales AS (
    SELECT
      su.sold_date_sk,
      su.item_sk,
      su.store_sk,
      su.channel,
      t.metric_pos,
      t.metric_value
    FROM sales_union su
    CROSS JOIN UNNEST(su.metrics_array) WITH ORDINALITY AS t(metric_value, metric_pos)
  ),

  -- Aggregate per item and channel
  item_agg AS (
    SELECT
      es.item_sk,
      es.channel,
      SUM(CASE WHEN es.metric_pos = 1 THEN es.metric_value ELSE 0 END) AS total_quantity,
      SUM(CASE WHEN es.metric_pos = 2 THEN es.metric_value ELSE 0 END) AS total_sales
    FROM expanded_sales es
    GROUP BY es.item_sk, es.channel
  ),

  -- Latest promotion name for each item using a LATERAL sub‑query
  item_promo AS (
    SELECT
      i.i_item_sk AS item_sk,
      i.i_product_name,
      lp.p_promo_name
    FROM item i
    LEFT JOIN LATERAL (
      SELECT p.p_promo_name
      FROM promotion p
      WHERE p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
        AND p.p_end_date_sk   >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
      ORDER BY p.p_start_date_sk DESC
      LIMIT 1
    ) lp ON TRUE
  ),

  -- Combine item aggregates with inventory, returns and promotion data
  final_agg AS (
    SELECT
      ip.i_product_name,
      ip.p_promo_name AS latest_promo,
      ia.channel,
      ia.total_quantity,
      ia.total_sales,
      COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand,
      COALESCE(ret.cr_return_quantity, 0)    AS total_return_qty,
      COALESCE(ret.cr_return_amount, 0)      AS total_return_amount
    FROM item_agg ia
    JOIN item i          ON ia.item_sk = i.i_item_sk
    LEFT JOIN item_promo ip ON i.i_item_sk = ip.item_sk
    LEFT JOIN inventory_info inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN returns_info ret   ON i.i_item_sk = ret.cr_item_sk
    WHERE ia.total_sales > 1000
  ),

  -- Scalar sub‑query to compute the overall average sales (used later)
  avg_sales_scalar AS (
    SELECT AVG(total_sales) AS avg_sales FROM final_agg
  )

SELECT
  fa.i_product_name,
  fa.latest_promo,
  fa.channel,
  fa.total_quantity,
  fa.total_sales,
  fa.inventory_on_hand,
  fa.total_return_qty,
  fa.total_return_amount,
  av.avg_sales
FROM final_agg fa
CROSS JOIN avg_sales_scalar av
WHERE fa.total_quantity > 10
  AND fa.inventory_on_hand > 0
  AND fa.total_return_qty < 100
ORDER BY fa.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
