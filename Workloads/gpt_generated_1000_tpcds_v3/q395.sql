WITH base AS (
   SELECT
      cs.cs_order_number,
      cs.cs_net_profit AS cs_net_profit,
      cs.cs_sold_date_sk,
      cp.cp_department,
      w.w_warehouse_name,
      w.w_state,
      s.s_store_name,
      s.s_floor_space,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ca.ca_state AS ca_state,
      cr.cr_net_loss,
      sr.sr_net_loss AS sr_net_loss,
      inv.inv_quantity_on_hand
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN store_returns sr
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN inventory inv
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
     AND cp.cp_department = 'Electronics'
     AND w.w_state = 'CA'
     AND s.s_floor_space > 8000000
     AND hd.hd_income_band_sk >= 12
     AND ca.ca_state = 'TX'
),
aggregated AS (
   SELECT
      s_store_name,
      w_warehouse_name,
      cp_department,
      SUM(cs_net_profit) AS total_sales,
      SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) AS total_return_loss,
      SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory
   FROM base
   GROUP BY s_store_name, w_warehouse_name, cp_department
   HAVING SUM(cs_net_profit) > 1000000
)
SELECT
   s_store_name,
   w_warehouse_name,
   cp_department,
   total_sales,
   total_return_loss,
   total_inventory,
   AVG(total_sales) OVER (PARTITION BY cp_department) AS avg_sales_by_department
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
