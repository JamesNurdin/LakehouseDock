WITH intersect_orders AS (
   SELECT cs_order_number AS order_number
   FROM catalog_sales
   WHERE cs_net_paid > 2000
   INTERSECT
   SELECT wr_order_number
   FROM web_returns
   WHERE wr_return_amt > 300
),
base AS (
   SELECT
      cp.cp_department,
      i.i_brand,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_coupon_amt,
      cs.cs_net_paid,
      cs.cs_net_profit,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wp.wp_type,
      CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE cp.cp_department = 'Electronics'
     AND i.i_brand = 'brand#12'
     AND cs.cs_coupon_amt > 100
     AND wr.wr_return_amt > 50
     AND i.i_rec_start_date > DATE '2000-01-01'
     AND wp.wp_type = 'content'
     AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
     AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number
          AND wr2.wr_return_quantity > 5
     )
),
agg AS (
   SELECT
      cp_department,
      i_brand,
      profit_flag,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(DISTINCT cs_order_number) AS orders_cnt
   FROM base
   GROUP BY cp_department, i_brand, profit_flag
)
SELECT
   cp_department,
   i_brand,
   profit_flag,
   total_net_paid,
   total_return_amt,
   orders_cnt,
   total_net_paid / NULLIF(orders_cnt, 0) AS avg_net_paid_per_order
FROM agg
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
LIMIT 100
