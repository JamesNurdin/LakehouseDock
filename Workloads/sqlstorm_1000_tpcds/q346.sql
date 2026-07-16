WITH sales_agg AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         SUM(cs.cs_net_paid) AS net_paid,
         SUM(cs.cs_ext_discount_amt) AS total_discount,
         COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cs.cs_bill_customer_sk

  UNION ALL

  SELECT ss.ss_customer_sk AS customer_sk,
         SUM(ss.ss_net_paid) AS net_paid,
         SUM(ss.ss_ext_discount_amt) AS total_discount,
         COUNT(*) AS order_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ss.ss_customer_sk

  UNION ALL

  SELECT ws.ws_bill_customer_sk AS customer_sk,
         SUM(ws.ws_net_paid) AS net_paid,
         SUM(ws.ws_ext_discount_amt) AS total_discount,
         COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ws.ws_bill_customer_sk
),
customer_totals AS (
  SELECT customer_sk,
         SUM(net_paid) AS total_net_paid,
         SUM(total_discount) AS total_discount,
         SUM(order_cnt) AS total_orders
  FROM sales_agg
  GROUP BY customer_sk
),
cust_demo AS (
  SELECT c.c_customer_sk,
         c.c_customer_id,
         ca.ca_state,
         ca.ca_city,
         cd.cd_gender,
         cd.cd_education_status,
         cd.cd_marital_status
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
cust_cat_sales AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         i.i_category,
         SUM(cs.cs_net_paid) AS net_paid
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cs.cs_bill_customer_sk, i.i_category

  UNION ALL

  SELECT ss.ss_customer_sk AS customer_sk,
         i.i_category,
         SUM(ss.ss_net_paid) AS net_paid
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ss.ss_customer_sk, i.i_category

  UNION ALL

  SELECT ws.ws_bill_customer_sk AS customer_sk,
         i.i_category,
         SUM(ws.ws_net_paid) AS net_paid
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ws.ws_bill_customer_sk, i.i_category
),
cust_fav_category AS (
  SELECT customer_sk,
         i_category AS favorite_category,
         net_paid AS favorite_category_spent,
         ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY net_paid DESC) AS rn
  FROM cust_cat_sales
),
favorite_category_per_customer AS (
  SELECT customer_sk,
         favorite_category,
         favorite_category_spent
  FROM cust_fav_category
  WHERE rn = 1
),
brand_sales AS (
  SELECT i.i_category,
         i.i_brand,
         SUM(cs.cs_net_paid) AS brand_net_paid
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category, i.i_brand
),
top_brand_per_category AS (
  SELECT i_category,
         i_brand AS top_brand,
         brand_net_paid,
         ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY brand_net_paid DESC) AS rn
  FROM brand_sales
),
top_brand AS (
  SELECT i_category,
         top_brand,
         brand_net_paid
  FROM top_brand_per_category
  WHERE rn = 1
),
ranked_customers AS (
  SELECT
    cd.c_customer_id,
    cd.ca_state,
    cd.ca_city,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_marital_status,
    ct.total_net_paid,
    ct.total_discount,
    ct.total_orders,
    ct.total_net_paid / NULLIF(ct.total_orders, 0) AS avg_spend_per_order,
    CASE WHEN ct.total_net_paid > 0 THEN ct.total_discount / ct.total_net_paid END AS discount_rate,
    f.favorite_category,
    f.favorite_category_spent,
    tb.top_brand,
    tb.brand_net_paid AS top_brand_sales,
    ROW_NUMBER() OVER (PARTITION BY cd.ca_state ORDER BY ct.total_net_paid DESC) AS state_rank
  FROM customer_totals ct
  JOIN cust_demo cd ON ct.customer_sk = cd.c_customer_sk
  LEFT JOIN favorite_category_per_customer f ON ct.customer_sk = f.customer_sk
  LEFT JOIN top_brand tb ON f.favorite_category = tb.i_category
)
SELECT *
FROM ranked_customers
WHERE state_rank <= 10
ORDER BY ca_state, total_net_paid DESC
