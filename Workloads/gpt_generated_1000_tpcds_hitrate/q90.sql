SELECT
  customer_id,
  item_id,
  promo_id,
  ship_type,
  warehouse_name,
  total_net_paid,
  avg_quantity,
  distinct_orders,
  min_sales_price,
  max_sales_price,
  ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM (
  SELECT
    c.c_customer_sk               AS customer_id,
    i.i_item_id                    AS item_id,
    p.p_promo_id                   AS promo_id,
    sm.sm_type                     AS ship_type,
    w.w_warehouse_name             AS warehouse_name,
    SUM(cs.cs_net_paid)           AS total_net_paid,
    AVG(cs.cs_quantity)           AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_ext_sales_price)    AS min_sales_price,
    MAX(cs.cs_ext_sales_price)    AS max_sales_price
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND sm.sm_type = 'OVERNIGHT'
    AND p.p_channel_catalog = 'N'
    AND p.p_start_date_sk = 2450316
    AND cs.cs_net_paid > (
          SELECT AVG(cs2.cs_net_paid)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2450316
        )
    AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_return_quantity > 0
        )
  GROUP BY
    c.c_customer_sk,
    i.i_item_id,
    p.p_promo_id,
    sm.sm_type,
    w.w_warehouse_name
) t
ORDER BY rn
LIMIT 100
