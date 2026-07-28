WITH base_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_warehouse_sk,
       cs.cs_promo_sk,
       cs.cs_net_paid,
       d_sold.d_year,
       t.t_hour,
       p.p_promo_name,
       cc.cc_name,
       w.w_warehouse_name,
       cp.cp_department,
       ca.ca_state AS bill_state,
       cd.cd_gender,
       s.s_store_name,
       s.s_state AS store_state,
       cs.cs_ship_addr_sk
   FROM catalog_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN store s
     ON s.s_closed_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2001
     AND t.t_hour BETWEEN 8 AND 12
     AND p.p_discount_active = 'Y'
     AND s.s_state = 'CA'
     AND cd.cd_gender = 'M'
     AND EXISTS (
         SELECT 1
         FROM customer_address ca_ship
         WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
           AND ca_ship.ca_state = 'CA'
     )
),
distinct_promos AS (
   SELECT DISTINCT s_store_name, p_promo_name
   FROM base_sales
)
SELECT
    bs.s_store_name,
    bs.p_promo_name,
    bs.d_year,
    SUM(bs.cs_net_paid) AS total_net_paid,
    RANK() OVER (PARTITION BY bs.s_store_name ORDER BY SUM(bs.cs_net_paid) DESC) AS store_sales_rank
FROM base_sales bs
JOIN distinct_promos dp
  ON bs.s_store_name = dp.s_store_name
 AND bs.p_promo_name = dp.p_promo_name
GROUP BY bs.s_store_name, bs.p_promo_name, bs.d_year
ORDER BY total_net_paid DESC
LIMIT 100
