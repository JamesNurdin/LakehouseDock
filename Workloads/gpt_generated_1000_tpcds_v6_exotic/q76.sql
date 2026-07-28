WITH base AS (
   SELECT
      c.c_customer_id AS customer_id,
      i.i_category AS category,
      cs.cs_net_profit AS catalog_net_profit,
      ws.ws_net_profit AS web_net_profit,
      cs.cs_ext_discount_amt + ws.ws_ext_discount_amt AS total_discount,
      cs.cs_quantity + ws.ws_quantity AS total_quantity,
      inv.inv_quantity_on_hand
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site ws_site
     ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
     AND i.i_category = 'Electronics'
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450600
     AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
     AND inv.inv_quantity_on_hand > 100
     AND cd.cd_gender = 'M'
     AND hd.hd_income_band_sk = 5
     AND cs.cs_ext_list_price > 5000
     AND ws.ws_ext_wholesale_cost < 2000
),
sales_agg AS (
   SELECT
      customer_id,
      category,
      SUM(catalog_net_profit) AS catalog_net_profit,
      SUM(web_net_profit) AS web_net_profit,
      SUM(total_discount) AS total_discount,
      SUM(total_quantity) AS total_quantity,
      COUNT(*) AS sales_cnt
   FROM base
   GROUP BY GROUPING SETS ((customer_id, category), (customer_id), (category))
),
avg_disc AS (
   SELECT AVG(total_discount) AS avg_total_discount FROM sales_agg
)
SELECT
   sa.customer_id,
   sa.category,
   sa.catalog_net_profit,
   sa.web_net_profit,
   sa.total_discount,
   sa.sales_cnt,
   DENSE_RANK() OVER (PARTITION BY sa.category ORDER BY (sa.catalog_net_profit + sa.web_net_profit) DESC) AS category_profit_rank,
   ROW_NUMBER() OVER (ORDER BY (sa.catalog_net_profit + sa.web_net_profit) DESC) AS overall_rank,
   CASE WHEN sa.total_discount > (SELECT avg_total_discount FROM avg_disc)
        THEN 'High Discount' ELSE 'Low Discount' END AS discount_level
FROM sales_agg sa
WHERE sa.category IS NOT NULL
ORDER BY overall_rank
LIMIT 100
