WITH
  filtered_customers AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      c.c_preferred_cust_flag,
      c.c_current_hdemo_sk,
      c.c_current_addr_sk
    FROM customer c
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
          AND hd.hd_income_band_sk > 10
      )
  ),
  promotion_names AS (
    SELECT DISTINCT
      p.p_promo_sk,
      p.p_promo_id,
      regexp_extract(p.p_promo_name, '^([A-Za-z]+)', 1) AS promo_category
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, 'Sale')
  ),
  agg AS (
    SELECT
      pn.p_promo_id,
      pn.promo_category,
      CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_customer,
      CASE WHEN fc.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
      d_sold.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN filtered_customers fc
      ON ws.ws_bill_customer_sk = fc.c_customer_sk
    JOIN promotion_names pn
      ON ws.ws_promo_sk = pn.p_promo_sk
    JOIN customer_address ca
      ON fc.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'San%'
    GROUP BY
      pn.p_promo_id,
      pn.promo_category,
      fc.c_first_name,
      fc.c_last_name,
      fc.c_preferred_cust_flag,
      d_sold.d_year
  )
SELECT
  a.p_promo_id,
  a.promo_category,
  a.full_customer,
  a.customer_type,
  a.d_year,
  a.total_sales,
  a.distinct_orders,
  SUM(a.total_sales) OVER (PARTITION BY a.p_promo_id ORDER BY a.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
  ROW_NUMBER() OVER (PARTITION BY a.p_promo_id ORDER BY a.total_sales DESC) AS rank_within_promo
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
