WITH cr_base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_net_loss,
    hd_refunded.hd_demo_sk,
    hd_refunded.hd_buy_potential,
    hd_refunded.hd_vehicle_count,
    wh_cr.w_warehouse_name,
    wh_cr.w_zip
  FROM catalog_returns cr
  JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
  JOIN warehouse wh_cr
    ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
  JOIN warehouse wh2
    ON cr.cr_warehouse_sk = wh2.w_warehouse_sk
)
SELECT
  cr_base.cr_returned_date_sk,
  cr_base.w_warehouse_name,
  cr_base.hd_buy_potential,
  CASE WHEN cr_base.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_indicator,
  SUM(cr_base.cr_net_loss) AS total_net_loss,
  sales_agg.total_sales_amount,
  sales_agg.total_coupon_amount,
  sales_agg.promo_distinct_cnt
FROM cr_base
LEFT JOIN LATERAL (
  SELECT
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_coupon_amt) AS total_coupon_amount,
    COUNT(DISTINCT p.p_promo_sk) AS promo_distinct_cnt
  FROM store_sales ss
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN promotion p2
    ON ss.ss_promo_sk = p2.p_promo_sk
  JOIN promotion p3
    ON ss.ss_promo_sk = p3.p_promo_sk
  JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
  JOIN household_demographics hd_store2
    ON ss.ss_hdemo_sk = hd_store2.hd_demo_sk
  WHERE ss.ss_hdemo_sk = cr_base.hd_demo_sk
) AS sales_agg ON TRUE
GROUP BY
  cr_base.cr_returned_date_sk,
  cr_base.w_warehouse_name,
  cr_base.hd_buy_potential,
  CASE WHEN cr_base.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END,
  sales_agg.total_sales_amount,
  sales_agg.total_coupon_amount,
  sales_agg.promo_distinct_cnt
ORDER BY total_net_loss DESC
LIMIT 100
