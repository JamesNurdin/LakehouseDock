WITH
  cs_agg AS (
    SELECT
      cs_ship_mode_sk,
      cs_warehouse_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_promo_sk,
      SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
      SUM(cs_coupon_amt) AS total_coupon,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 1000
      AND cs_coupon_amt BETWEEN 100 AND 1500
      AND cs_sold_date_sk BETWEEN 2450000 AND 2453650
      AND cs_quantity > 0
      AND cs_wholesale_cost < 100
      AND cs_list_price > cs_wholesale_cost
    GROUP BY cs_ship_mode_sk, cs_warehouse_sk, cs_sold_date_sk, cs_sold_time_sk, cs_promo_sk
  ),
  wr_agg AS (
    SELECT
      wr_returned_time_sk,
      wr_refunded_customer_sk,
      wr_refunded_cdemo_sk,
      wr_reason_sk,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 50
      AND wr_return_quantity > 0
      AND wr_returned_time_sk IS NOT NULL
      AND wr_refunded_customer_sk IS NOT NULL
      AND wr_reason_sk IS NOT NULL
    GROUP BY wr_returned_time_sk, wr_refunded_customer_sk, wr_refunded_cdemo_sk, wr_reason_sk
  ),
  sales_enriched AS (
    SELECT
      cs_agg.cs_ship_mode_sk,
      cs_agg.cs_warehouse_sk,
      cs_agg.cs_sold_date_sk,
      cs_agg.cs_sold_time_sk,
      cs_agg.cs_promo_sk,
      cs_agg.total_net_paid,
      cs_agg.total_coupon,
      cs_agg.sales_cnt,
      sm.sm_carrier,
      sm.sm_type,
      w.w_warehouse_name,
      p.p_promo_name,
      td.t_hour,
      CASE
        WHEN cs_agg.total_net_paid > 5000 THEN 'HIGH'
        WHEN cs_agg.total_net_paid BETWEEN 2000 AND 5000 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS revenue_band
    FROM cs_agg
    JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs_agg.cs_sold_time_sk = td.t_time_sk
  ),
  returns_enriched AS (
    SELECT
      wr_agg.wr_returned_time_sk,
      wr_agg.wr_refunded_customer_sk,
      wr_agg.wr_refunded_cdemo_sk,
      wr_agg.wr_reason_sk,
      wr_agg.total_return_amt,
      wr_agg.return_cnt,
      r.r_reason_desc,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      td.t_hour
    FROM wr_agg
    JOIN reason r ON wr_agg.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr_agg.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr_agg.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON wr_agg.wr_returned_time_sk = td.t_time_sk
  ),
  inventory_agg AS (
    SELECT
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_item_sk IS NOT NULL
    GROUP BY inv_warehouse_sk
  ),
  inventory_warehouse AS (
    SELECT
      ia.inv_warehouse_sk,
      w.w_warehouse_name,
      ia.total_on_hand
    FROM inventory_agg ia
    JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
  ),
  sales_inventory_full AS (
    SELECT
      COALESCE(se.cs_warehouse_sk, iw.inv_warehouse_sk) AS warehouse_sk,
      COALESCE(se.w_warehouse_name, iw.w_warehouse_name) AS warehouse_name,
      se.total_net_paid,
      se.revenue_band,
      iw.total_on_hand
    FROM sales_enriched se
    FULL OUTER JOIN inventory_warehouse iw
      ON se.cs_warehouse_sk = iw.inv_warehouse_sk
  ),
  unioned AS (
    SELECT
      sif.warehouse_name,
      sif.total_net_paid,
      sif.revenue_band,
      sif.total_on_hand,
      'sales_inventory' AS src_type
    FROM sales_inventory_full sif
    UNION DISTINCT
    SELECT
      NULL AS warehouse_name,
      NULL AS total_net_paid,
      NULL AS revenue_band,
      NULL AS total_on_hand,
      'returns' AS src_type
    FROM returns_enriched
  )
SELECT
  u.warehouse_name,
  u.total_net_paid,
  u.revenue_band,
  u.total_on_hand,
  u.src_type,
  (SELECT AVG(total_net_paid) FROM sales_enriched) AS avg_sales_net_paid
FROM unioned u
WHERE u.total_net_paid IS NOT NULL
   OR u.total_on_hand IS NOT NULL
ORDER BY u.warehouse_name
LIMIT 100
