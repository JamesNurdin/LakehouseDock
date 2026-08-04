WITH sales_without_return AS (
   SELECT cs_item_sk
   FROM catalog_sales
   EXCEPT
   SELECT sr_item_sk
   FROM store_returns
),
base AS (
   SELECT
     cs.cs_ext_sales_price,
     cs.cs_net_profit,
     i.i_item_id,
     i.i_item_sk,
     i.i_product_name,
     d_sold.d_year,
     d_sold.d_date,
     p.p_cost,
     cp.cp_department,
     sm.sm_type,
     cust.c_customer_id,
     cd.cd_gender,
     inv.inv_quantity_on_hand,
     s.s_store_name,
     sr.sr_return_quantity,
     sr.sr_return_amt
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
   JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer cust_ret ON sr.sr_customer_sk = cust_ret.c_customer_sk
   JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
   WHERE i.i_item_sk IN (SELECT cs_item_sk FROM sales_without_return)
),
agg AS (
   SELECT
     i_item_id,
     d_year,
     SUM(cs_ext_sales_price) AS total_sales,
     SUM(cs_net_profit) AS total_profit,
     CASE WHEN SUM(cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
     AVG(p_cost) AS avg_promo_cost
   FROM base
   GROUP BY GROUPING SETS (
     (i_item_id, d_year),
     (i_item_id)
   )
)
SELECT
  i_item_id,
  d_year,
  total_sales,
  total_profit,
  profit_category,
  avg_promo_cost,
  SUM(total_profit) OVER (
    PARTITION BY i_item_id
    ORDER BY d_year NULLS FIRST
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_profit
FROM agg
ORDER BY total_sales DESC
LIMIT 100
