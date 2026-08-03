WITH aggregated AS (
  SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(i.inv_quantity_on_hand) AS total_inventory
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
  JOIN tpcds.customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND s.s_state = 'CA'
    AND p.p_channel_email = 'Y'
    AND cc.cc_manager = 'Thomas Benton'
    AND i.inv_quantity_on_hand > 500
  GROUP BY CUBE (d.d_year, s.s_store_name, p.p_promo_name)
),
second_agg AS (
  SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(i.inv_quantity_on_hand) AS total_inventory
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp ON wp.wp_access_date_sk = d.d_date_sk
  JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
  JOIN tpcds.customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
  WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    AND s.s_state = 'TX'
    AND p.p_channel_tv = 'Y'
    AND cc.cc_manager = 'Charles Bartley'
    AND i.inv_quantity_on_hand > 600
  GROUP BY CUBE (d.d_year, s.s_store_name, p.p_promo_name)
)
SELECT
  a.d_year,
  a.s_store_name,
  a.p_promo_name,
  a.total_sales,
  a.total_returns,
  a.total_inventory,
  ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_sales DESC) AS sales_rank,
  CASE WHEN a.total_sales > (SELECT AVG(ss.ss_ext_sales_price) FROM tpcds.store_sales ss) THEN 'HIGH' ELSE 'LOW' END AS sales_category
FROM (
  SELECT d_year, s_store_name, p_promo_name, total_sales, total_returns, total_inventory FROM aggregated
  UNION
  SELECT d_year, s_store_name, p_promo_name, total_sales, total_returns, total_inventory FROM second_agg
) a
WHERE a.total_inventory IS NOT NULL
ORDER BY a.total_sales DESC
LIMIT 100
