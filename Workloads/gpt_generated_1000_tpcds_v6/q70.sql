WITH base AS (
   SELECT
     hd.hd_buy_potential,
     i.i_brand,
     cs.cs_order_number,
     cr.cr_return_amount,
     cs.cs_net_paid_inc_ship_tax,
     i.i_current_price
   FROM catalog_returns cr
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN household_demographics hd
     ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_buy_potential IN ('1001-5000', '>10000')
     AND hd.hd_dep_count >= 5
     AND i.i_current_price BETWEEN 100 AND 500
     AND cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
     AND cr.cr_store_credit > 50
),
agg AS (
   SELECT
     hd_buy_potential,
     i_brand,
     SUM(cr_return_amount) AS total_return_amount,
     SUM(cs_net_paid_inc_ship_tax) AS total_sales_amount,
     COUNT(DISTINCT cs_order_number) AS distinct_orders,
     AVG(i_current_price) AS avg_item_price
   FROM base
   GROUP BY ROLLUP (hd_buy_potential, i_brand)
)
SELECT
  hd_buy_potential,
  i_brand,
  total_return_amount,
  total_sales_amount,
  distinct_orders,
  avg_item_price,
  ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY total_return_amount DESC) AS return_rank_within_potential
FROM agg
ORDER BY hd_buy_potential, i_brand
LIMIT 100
