WITH filtered_promotions AS (
   SELECT DISTINCT
          p_promo_sk,
          p_promo_name,
          CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
   FROM promotion
   WHERE p_channel_event = 'N' AND p_channel_press = 'N'
),
distinct_warehouses AS (
   SELECT DISTINCT
          w_warehouse_sk,
          w_warehouse_name
   FROM warehouse
   WHERE w_country = 'United States'
)
SELECT *
FROM (
   SELECT
       'Catalog' AS sales_source,
       dw.w_warehouse_name AS location,
       fp.p_promo_name,
       fp.promo_status,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
   FROM catalog_sales cs
   JOIN filtered_promotions fp ON cs.cs_promo_sk = fp.p_promo_sk
   JOIN distinct_warehouses dw ON cs.cs_warehouse_sk = dw.w_warehouse_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175
   GROUP BY dw.w_warehouse_name, fp.p_promo_name, fp.promo_status

   UNION ALL

   SELECT
       'Store' AS sales_source,
       ca.ca_city AS location,
       fp.p_promo_name,
       fp.promo_status,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
       CASE WHEN SUM(ss.ss_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_category
   FROM store_sales ss
   JOIN filtered_promotions fp ON ss.ss_promo_sk = fp.p_promo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451175
   GROUP BY ca.ca_city, fp.p_promo_name, fp.promo_status
) AS combined
ORDER BY total_profit DESC
LIMIT 100
