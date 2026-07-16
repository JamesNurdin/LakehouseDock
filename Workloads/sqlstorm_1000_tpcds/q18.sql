WITH
customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END AS cust_type,
    ca.ca_city,
    ca.ca_state
  FROM customer c
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
catalog_sales_detail AS (
  SELECT
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    d.d_date,
    (SELECT COALESCE(MAX(p.p_cost), 0)
       FROM promotion p
      WHERE p.p_item_sk = cs.cs_item_sk
        AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS max_promo_cost
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
),
catalog_sales_agg AS (
  SELECT
    cust_sk,
    SUM(cs_net_paid) AS catalog_net_paid,
    SUM(cs_net_profit) AS catalog_net_profit,
    SUM(cs_ext_discount_amt) AS catalog_total_discount,
    SUM(max_promo_cost) AS catalog_total_max_promo_cost,
    COUNT(*) AS catalog_orders,
    MAX(d_date) AS catalog_last_sale_date
  FROM catalog_sales_detail
  GROUP BY cust_sk
),
web_sales_detail AS (
  SELECT
    ws.ws_bill_customer_sk AS cust_sk,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    d.d_date,
    t.t_hour,
    COALESCE(p.p_cost, 0) AS promo_cost
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2002
),
web_sales_agg AS (
  SELECT
    cust_sk,
    SUM(ws_net_paid) AS web_net_paid,
    SUM(ws_net_profit) AS web_net_profit,
    SUM(ws_ext_discount_amt) AS web_total_discount,
    SUM(promo_cost) AS web_total_promo_cost,
    COUNT(*) AS web_orders,
    MAX(d_date) AS web_last_sale_date
  FROM web_sales_detail
  GROUP BY cust_sk
),
store_sales_detail AS (
  SELECT
    ss.ss_customer_sk AS cust_sk,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_ext_discount_amt,
    d.d_date,
    s.s_state,
    s.s_city
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
),
store_sales_agg AS (
  SELECT
    cust_sk,
    SUM(ss_net_paid) AS store_net_paid,
    SUM(ss_net_profit) AS store_net_profit,
    SUM(ss_ext_discount_amt) AS store_total_discount,
    COUNT(*) AS store_orders,
    MAX(d_date) AS store_last_sale_date,
    MAX(s_state) AS store_state,
    MAX(s_city) AS store_city
  FROM store_sales_detail
  GROUP BY cust_sk
),
all_customers AS (
  SELECT cust_sk FROM catalog_sales_agg
  UNION
  SELECT cust_sk FROM web_sales_agg
  UNION
  SELECT cust_sk FROM store_sales_agg
),
customer_sales_combined AS (
  SELECT
    ac.cust_sk,
    COALESCE(csa.catalog_net_paid, 0) AS catalog_net_paid,
    COALESCE(csa.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(wsa.web_net_paid, 0) AS web_net_paid,
    COALESCE(wsa.web_net_profit, 0) AS web_net_profit,
    COALESCE(ssa.store_net_paid, 0) AS store_net_paid,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(csa.catalog_total_discount, 0) + COALESCE(wsa.web_total_discount, 0) + COALESCE(ssa.store_total_discount, 0) AS total_discount,
    COALESCE(csa.catalog_total_max_promo_cost, 0) + COALESCE(wsa.web_total_promo_cost, 0) AS total_promo_cost,
    GREATEST(
      COALESCE(csa.catalog_last_sale_date, DATE '1900-01-01'),
      COALESCE(wsa.web_last_sale_date, DATE '1900-01-01'),
      COALESCE(ssa.store_last_sale_date, DATE '1900-01-01')
    ) AS last_purchase_date,
    COALESCE(csa.catalog_orders, 0) + COALESCE(wsa.web_orders, 0) + COALESCE(ssa.store_orders, 0) AS total_orders,
    COALESCE(ssa.store_state, 'UNKNOWN') AS store_state,
    COALESCE(ssa.store_city, 'UNKNOWN') AS store_city
  FROM all_customers ac
  LEFT JOIN catalog_sales_agg csa ON ac.cust_sk = csa.cust_sk
  LEFT JOIN web_sales_agg wsa ON ac.cust_sk = wsa.cust_sk
  LEFT JOIN store_sales_agg ssa ON ac.cust_sk = ssa.cust_sk
),
final_result AS (
  SELECT
    ci.c_customer_id,
    ci.full_name,
    ci.cust_type,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    cs.cust_sk,
    cs.catalog_net_paid + cs.web_net_paid + cs.store_net_paid AS total_net_paid,
    cs.catalog_net_profit + cs.web_net_profit + cs.store_net_profit AS total_net_profit,
    cs.total_discount,
    cs.total_promo_cost,
    cs.last_purchase_date,
    cs.total_orders,
    cs.store_state,
    cs.store_city,
    CASE
      WHEN (cs.catalog_net_profit + cs.web_net_profit + cs.store_net_profit) > 10000 THEN 'High'
      WHEN (cs.catalog_net_profit + cs.web_net_profit + cs.store_net_profit) > 1000 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    date_diff('year', cs.last_purchase_date, DATE '2024-10-01') AS years_since_last_purchase,
    ROW_NUMBER() OVER (ORDER BY (cs.catalog_net_profit + cs.web_net_profit + cs.store_net_profit) DESC) AS profit_rank
  FROM customer_sales_combined cs
  JOIN customer_info ci ON cs.cust_sk = ci.c_customer_sk
)
SELECT *
FROM final_result
ORDER BY profit_rank
LIMIT 100
