WITH sales_a AS (
   SELECT s.s_store_id,
          i.i_category,
          i.i_brand,
          d_sold.d_year,
          SUM(cs.cs_net_paid) AS total_net_paid,
          AVG(cs.cs_quantity) AS avg_quantity,
          COUNT(*) AS order_cnt,
          CASE WHEN SUM(cs.cs_ext_discount_amt) > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_level
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2001
     AND i.i_category = 'Books'
     AND i.i_brand = 'corpbrand #6'
     AND s.s_state = 'CA'
     AND cs.cs_quantity > 5
   GROUP BY s.s_store_id, i.i_category, i.i_brand, d_sold.d_year
),
sales_b AS (
   SELECT s.s_store_id,
          i.i_category,
          i.i_brand,
          d_sold.d_year,
          SUM(cs.cs_net_paid) AS total_net_paid,
          AVG(cs.cs_quantity) AS avg_quantity,
          COUNT(*) AS order_cnt,
          CASE WHEN SUM(cs.cs_ext_discount_amt) > 500 THEN 'High Discount' ELSE 'Low Discount' END AS discount_level
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
   JOIN web_page wp ON wp.wp_access_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2002
     AND i.i_category = 'Music'
     AND i.i_brand = 'edu packbrand #4'
     AND s.s_state = 'TX'
     AND cs.cs_quantity BETWEEN 1 AND 3
   GROUP BY s.s_store_id, i.i_category, i.i_brand, d_sold.d_year
)
SELECT
   u.s_store_id,
   u.i_category,
   u.i_brand,
   u.d_year,
   SUM(u.total_net_paid) AS agg_total_net_paid,
   AVG(u.avg_quantity) AS agg_avg_quantity,
   SUM(u.order_cnt) AS agg_order_cnt,
   CASE WHEN SUM(u.total_net_paid) > 10000 THEN 'Very High Sales' ELSE 'Normal Sales' END AS sales_tier,
   ROW_NUMBER() OVER (ORDER BY SUM(u.total_net_paid) DESC) AS row_num
FROM (
   SELECT * FROM sales_a
   UNION
   SELECT * FROM sales_b
) u
GROUP BY u.s_store_id, u.i_category, u.i_brand, u.d_year
ORDER BY agg_total_net_paid DESC
LIMIT 100
