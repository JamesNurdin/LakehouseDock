WITH joined AS (
  SELECT
    cc.cc_name,
    d_cs.d_month_seq,
    hd.hd_buy_potential,
    cs.cs_ext_sales_price,
    ss.ss_ext_sales_price,
    cs.cs_order_number,
    ib.ib_upper_bound,
    cs.cs_wholesale_cost,
    cs.cs_list_price,
    wp.wp_url,
    split(wp.wp_url, '/') AS url_parts
  FROM call_center cc
  JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d_cs.d_date_sk
                     AND ss.ss_sold_time_sk = t_cs.t_time_sk
                     AND ss.ss_customer_sk = cust.c_customer_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
                       AND sr.sr_customer_sk = cust.c_customer_sk
  JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
  JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
  WHERE cc.cc_state = 'CA'
    AND d_cs.d_year = 2001
    AND ca.ca_street_type = 'Blvd'
),
exploded AS (
  SELECT
    j.*,
    url_part
  FROM joined j
  CROSS JOIN UNNEST(j.url_parts) AS t(url_part)
),
agg1 AS (
  SELECT
    cc_name,
    d_month_seq,
    hd_buy_potential,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(ib_upper_bound) AS avg_income_upper,
    MIN(cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs_list_price) AS max_list_price
  FROM exploded
  GROUP BY cc_name, d_month_seq, hd_buy_potential
),
agg2 AS (
  SELECT
    cc_name,
    d_month_seq,
    hd_buy_potential,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(ib_upper_bound) AS avg_income_upper,
    MIN(cs_wholesale_cost) AS min_wholesale_cost,
    MAX(cs_list_price) AS max_list_price
  FROM exploded
  WHERE url_part LIKE 'http%'
  GROUP BY cc_name, d_month_seq, hd_buy_potential
),
unioned AS (
  SELECT * FROM agg1
  UNION
  SELECT * FROM agg2
),
ranked AS (
  SELECT
    u.*,
    ROW_NUMBER() OVER (ORDER BY total_catalog_sales DESC) AS global_row_num,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_catalog_sales DESC) AS grp_rank
  FROM unioned u
)
SELECT
  cc_name,
  d_month_seq,
  hd_buy_potential,
  total_catalog_sales,
  total_store_sales,
  distinct_orders,
  avg_income_upper,
  min_wholesale_cost,
  max_list_price,
  global_row_num,
  grp_rank
FROM ranked
WHERE grp_rank <= 5
ORDER BY total_catalog_sales DESC
LIMIT 100
