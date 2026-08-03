WITH
  -- Aggregate catalog sales per key set
  cs_agg AS (
    SELECT
      cs.cs_sold_time_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      SUM(cs.cs_ext_sales_price)   AS cs_total_sales,
      SUM(cs.cs_ext_discount_amt) AS cs_total_discount,
      COUNT(*)                     AS cs_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000          -- predicate 1
      AND cs.cs_coupon_amt      < 500           -- predicate 2
      AND cs.cs_quantity        >= 1            -- predicate 3
    GROUP BY cs.cs_sold_time_sk,
             cs.cs_bill_hdemo_sk,
             cs.cs_ship_hdemo_sk,
             cs.cs_bill_addr_sk,
             cs.cs_ship_addr_sk,
             cs.cs_catalog_page_sk,
             cs.cs_warehouse_sk
  ),

  -- Aggregate web sales per key set
  ws_agg AS (
    SELECT
      ws.ws_sold_time_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_ship_addr_sk,
      ws.ws_web_page_sk,
      ws.ws_warehouse_sk,
      SUM(ws.ws_ext_sales_price)   AS ws_total_sales,
      SUM(ws.ws_ext_discount_amt) AS ws_total_discount,
      COUNT(*)                     AS ws_cnt
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 500         -- predicate 4
      AND ws.ws_coupon_amt      < 300          -- predicate 5
      AND ws.ws_quantity        >= 1           -- predicate 6
    GROUP BY ws.ws_sold_time_sk,
             ws.ws_bill_hdemo_sk,
             ws.ws_ship_hdemo_sk,
             ws.ws_bill_addr_sk,
             ws.ws_ship_addr_sk,
             ws.ws_web_page_sk,
             ws.ws_warehouse_sk
  ),

  -- Aggregate inventory per warehouse
  inventory_agg AS (
    SELECT
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY inv.inv_warehouse_sk
  )

SELECT
  'catalog'                              AS source_type,
  cp.cp_department                       AS department,
  w.w_warehouse_name                     AS warehouse_name,
  t.t_hour                               AS hour_of_day,
  hd_bill.hd_buy_potential               AS buy_potential,
  ib.ib_upper_bound                      AS income_upper_bound,
  cs_agg.cs_total_sales                  AS total_sales,
  cs_agg.cs_total_discount               AS total_discount,
  CASE WHEN cs_agg.cs_total_discount > 500 THEN 'HIGH' ELSE 'LOW' END AS discount_level,
  ROW_NUMBER() OVER (PARTITION BY 'catalog' ORDER BY cs_agg.cs_total_sales DESC) AS rank_in_source,
  (SELECT COUNT(*)
     FROM (SELECT cs_order_number FROM catalog_sales)
     EXCEPT
     SELECT ss_ticket_number FROM store_sales)                         AS missing_order_cnt,
  letter                                                               -- from UNNEST
FROM cs_agg
JOIN catalog_page cp                ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w                     ON cs_agg.cs_warehouse_sk   = w.w_warehouse_sk
JOIN time_dim t                      ON cs_agg.cs_sold_time_sk  = t.t_time_sk
JOIN household_demographics hd_bill ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib                  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss                  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s                         ON ss.ss_store_sk = s.s_store_sk
JOIN inventory_agg inv               ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr           ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN customer_address ca_bill       ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
CROSS JOIN (SELECT 1 AS dummy)     
CROSS JOIN UNNEST(ARRAY['X','Y']) AS u(letter)
WHERE t.t_hour BETWEEN 8 AND 20
  AND w.w_gmt_offset BETWEEN -5 AND 5
  AND ib.ib_upper_bound > 100000

UNION

SELECT
  'web'                                 AS source_type,
  wp.wp_type                            AS department,
  w2.w_warehouse_name                   AS warehouse_name,
  t2.t_hour                             AS hour_of_day,
  hd_bill2.hd_buy_potential             AS buy_potential,
  ib2.ib_upper_bound                    AS income_upper_bound,
  ws_agg.ws_total_sales                 AS total_sales,
  ws_agg.ws_total_discount              AS total_discount,
  CASE WHEN ws_agg.ws_total_discount > 500 THEN 'HIGH' ELSE 'LOW' END AS discount_level,
  ROW_NUMBER() OVER (PARTITION BY 'web' ORDER BY ws_agg.ws_total_sales DESC) AS rank_in_source,
  (SELECT COUNT(*)
     FROM (SELECT cs_order_number FROM catalog_sales)
     EXCEPT
     SELECT ss_ticket_number FROM store_sales)                         AS missing_order_cnt,
  letter                                                               -- from UNNEST
FROM ws_agg
JOIN web_page wp               ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w2                ON ws_agg.ws_warehouse_sk = w2.w_warehouse_sk
JOIN time_dim t2                 ON ws_agg.ws_sold_time_sk  = t2.t_time_sk
JOIN household_demographics hd_bill2 ON ws_agg.ws_bill_hdemo_sk = hd_bill2.hd_demo_sk
JOIN income_band ib2                ON hd_bill2.hd_income_band_sk = ib2.ib_income_band_sk
JOIN store_sales ss2               ON ss2.ss_sold_time_sk = t2.t_time_sk
JOIN store s2                      ON ss2.ss_store_sk = s2.s_store_sk
JOIN inventory_agg inv2            ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
LEFT JOIN store_returns sr2        ON sr2.sr_ticket_number = ss2.ss_ticket_number
JOIN customer_address ca_bill2    ON ws_agg.ws_bill_addr_sk = ca_bill2.ca_address_sk
CROSS JOIN (SELECT 1 AS dummy)
CROSS JOIN UNNEST(ARRAY['X','Y']) AS u(letter)
WHERE t2.t_hour BETWEEN 8 AND 20
  AND w2.w_gmt_offset BETWEEN -5 AND 5
  AND ib2.ib_upper_bound > 100000

ORDER BY total_sales DESC
LIMIT 100
