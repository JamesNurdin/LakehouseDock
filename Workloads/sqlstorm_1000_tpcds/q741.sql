WITH store_customers AS (
    SELECT ss_customer_sk AS cust_sk FROM store_sales
),
web_customers AS (
    SELECT ws_bill_customer_sk AS cust_sk FROM web_sales
),
intersect_customers AS (
    SELECT cust_sk FROM store_customers INTERSECT SELECT cust_sk FROM web_customers
),
channel_sales AS (
    SELECT cs.cs_call_center_sk AS call_center_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           'catalog' AS channel,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_coupon_amt AS coupon_amt,
           cs.cs_ext_tax AS tax_amount,
           cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    WHERE cs.cs_call_center_sk IS NOT NULL

    UNION ALL

    SELECT s.s_store_sk AS call_center_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS net_paid,
           'store' AS channel,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_ext_discount_amt AS discount_amt,
           ss.ss_coupon_amt AS coupon_amt,
           ss.ss_ext_tax AS tax_amount,
           ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT w.w_warehouse_sk AS call_center_sk,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_paid AS net_paid,
           'web' AS channel,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_ext_discount_amt AS discount_amt,
           ws.ws_coupon_amt AS coupon_amt,
           ws.ws_ext_tax AS tax_amount,
           ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
customer_sales AS (
    SELECT cs.call_center_sk,
           cs.customer_sk,
           d.d_year,
           SUM(cs.net_paid) AS total_net_paid,
           SUM(cs.ext_sales_price) AS total_ext_sales,
           SUM(cs.discount_amt) AS total_discount,
           SUM(cs.tax_amount) AS total_tax,
           SUM(cs.net_profit) AS total_profit,
           COUNT(*) AS transaction_count,
           AVG(cs.quantity) AS avg_quantity,
           ROW_NUMBER() OVER (PARTITION BY cs.call_center_sk ORDER BY SUM(cs.net_paid) DESC) AS rn
    FROM channel_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cs.customer_sk IN (SELECT cust_sk FROM intersect_customers)
    GROUP BY cs.call_center_sk, cs.customer_sk, d.d_year
),
top_customers AS (
    SELECT cs.call_center_sk,
           cs.customer_sk,
           cs.total_net_paid,
           cs.total_ext_sales,
           cs.total_profit,
           cs.transaction_count,
           cs.avg_quantity,
           cs.d_year,
           c.c_first_name,
           c.c_last_name,
           COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
           cs.rn
    FROM customer_sales cs
    JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cs.rn <= 5
),
call_center_info AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_city,
           cc.cc_state,
           cc.cc_country,
           CONCAT(cc.cc_street_number, ' ', cc.cc_street_name, ' ', cc.cc_street_type) AS full_address,
           cc.cc_gmt_offset,
           cc.cc_tax_percentage,
           CASE 
               WHEN cc.cc_closed_date_sk IS NULL THEN 'OPEN'
               ELSE 'CLOSED'
           END AS status
    FROM call_center cc
)
SELECT 
    ci.cc_call_center_sk,
    ci.full_address,
    ci.cc_name,
    ci.status,
    t.d_year,
    t.customer_sk,
    CONCAT(t.c_first_name, ' ', t.c_last_name) AS customer_name,
    t.gender,
    t.total_net_paid,
    t.total_ext_sales,
    t.total_profit,
    t.transaction_count,
    ROUND(t.avg_quantity, 2) AS avg_quantity,
    CASE 
        WHEN t.total_net_paid > 0 THEN ROUND(t.total_profit / t.total_net_paid * 100, 2)
        ELSE NULL
    END AS profit_margin_percent,
    (SELECT AVG(cs.total_net_paid) 
     FROM top_customers cs 
     WHERE cs.call_center_sk = ci.cc_call_center_sk AND cs.d_year = t.d_year) AS avg_net_paid_per_cc_year,
    ROW_NUMBER() OVER (PARTITION BY ci.cc_call_center_sk ORDER BY t.total_net_paid DESC) AS rank_in_call_center
FROM top_customers t
LEFT JOIN call_center_info ci ON t.call_center_sk = ci.cc_call_center_sk
ORDER BY ci.cc_call_center_sk ASC NULLS FIRST, t.total_net_paid DESC
