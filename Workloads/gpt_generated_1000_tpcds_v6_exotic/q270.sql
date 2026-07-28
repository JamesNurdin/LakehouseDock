WITH
  -- Aggregate inventory per warehouse
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
  ),
  -- Sales‑focused view (positive revenue)
  sales_view AS (
    SELECT
      cp.cp_catalog_number               AS catalog_number,
      w.w_warehouse_name                 AS warehouse_name,
      sm.sm_type                         AS ship_mode_type,
      p.p_promo_name                     AS promo_name,
      SUM(cs.cs_ext_sales_price)         AS total_sales,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
      COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
      t.t_hour                           AS hour_of_day,
      i.total_qty                        AS inventory_qty
    FROM catalog_sales cs
    JOIN catalog_page cp   ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm      ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w       ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion p       ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN time_dim t        ON cs.cs_sold_time_sk   = t.t_time_sk
    LEFT JOIN inv_agg i    ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM inventory inv_raw
            WHERE inv_raw.inv_warehouse_sk = w.w_warehouse_sk
              AND inv_raw.inv_quantity_on_hand = 0
          )
    GROUP BY
      cp.cp_catalog_number,
      w.w_warehouse_name,
      sm.sm_type,
      p.p_promo_name,
      t.t_hour,
      i.total_qty
  ),
  -- Returns‑focused view (negative impact, still using the same dimensions)
  returns_view AS (
    SELECT
      cp.cp_catalog_number               AS catalog_number,
      w.w_warehouse_name                 AS warehouse_name,
      sm.sm_type                         AS ship_mode_type,
      p.p_promo_name                     AS promo_name,
      -SUM(sr.sr_return_amt)             AS total_sales,
      CASE WHEN SUM(sr.sr_return_amt) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
      COUNT(DISTINCT sr.sr_ticket_number) AS orders_cnt,
      tr.t_hour                          AS hour_of_day,
      i.total_qty                        AS inventory_qty
    FROM store_returns sr
    JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim tr       ON sr.sr_return_time_sk = tr.t_time_sk
    -- Pull sales‑related dimensions through the same time key
    JOIN catalog_sales cs  ON cs.cs_sold_time_sk = tr.t_time_sk
    JOIN catalog_page cp   ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm      ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w       ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion p       ON cs.cs_promo_sk       = p.p_promo_sk
    LEFT JOIN inv_agg i    ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM inventory inv_raw
            WHERE inv_raw.inv_warehouse_sk = w.w_warehouse_sk
              AND inv_raw.inv_quantity_on_hand = 0
          )
    GROUP BY
      cp.cp_catalog_number,
      w.w_warehouse_name,
      sm.sm_type,
      p.p_promo_name,
      tr.t_hour,
      i.total_qty
  )
SELECT * FROM sales_view
UNION ALL
SELECT * FROM returns_view
ORDER BY total_sales DESC
LIMIT 100
