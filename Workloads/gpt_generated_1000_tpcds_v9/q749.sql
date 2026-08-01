WITH grouped_sales AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_id,
    w.w_warehouse_id,
    sm.sm_ship_mode_id,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_quantity) + SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(ss.ss_net_profit) AS avg_store_profit
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   AND cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  WHERE
    p.p_channel_catalog = 'N'
    AND p.p_start_date_sk BETWEEN 2450324 AND 2450623
    AND w.w_country = 'United States'
    AND hd.hd_buy_potential = '>10000'
    AND inv.inv_quantity_on_hand > 0
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
    AND i.i_brand = 'BrandA'
    AND cr.cr_order_number IS NULL
  GROUP BY
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_id,
    w.w_warehouse_id,
    sm.sm_ship_mode_id
)
SELECT
  gs.i_item_id,
  gs.i_product_name,
  gs.p_promo_id,
  gs.w_warehouse_id,
  gs.sm_ship_mode_id,
  gs.total_store_sales,
  gs.total_catalog_sales,
  gs.total_quantity,
  gs.distinct_customers,
  gs.avg_store_profit,
  (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = gs.i_item_sk
  ) AS avg_item_store_profit,
  SUM(gs.total_store_sales) OVER (
    ORDER BY gs.total_store_sales DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_store_sales
FROM grouped_sales gs
ORDER BY gs.total_store_sales DESC
LIMIT 100
