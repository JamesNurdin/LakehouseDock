WITH
  sales AS (
    SELECT
      cs_sold_date_sk,
      cs_ship_date_sk,
      cs_bill_customer_sk,
      cs_bill_cdemo_sk,
      cs_bill_addr_sk,
      cs_ship_customer_sk,
      cs_ship_cdemo_sk,
      cs_ship_addr_sk,
      cs_ship_mode_sk,
      cs_promo_sk,
      cs_item_sk,
      cs_quantity,
      cs_ext_sales_price,
      cs_net_profit
    FROM catalog_sales
  ),
  date_sold AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
  ),
  date_ship AS (
    SELECT d_date_sk, d_year AS ship_year, d_month_seq AS ship_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
  ),
  cust_bill AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year
    FROM customer
  ),
  cust_ship AS (
    SELECT c_customer_sk, c_email_address
    FROM customer
  ),
  demog_bill AS (
    SELECT cd_demo_sk, cd_gender, cd_education_status
    FROM customer_demographics
  ),
  demog_ship AS (
    SELECT cd_demo_sk, cd_credit_rating
    FROM customer_demographics
  ),
  addr_bill AS (
    SELECT ca_address_sk, ca_state, ca_city
    FROM customer_address
  ),
  addr_ship AS (
    SELECT ca_address_sk, ca_country
    FROM customer_address
  ),
  promo AS (
    SELECT p_promo_sk, p_promo_name, p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  ship AS (
    SELECT sm_ship_mode_sk, sm_type
    FROM ship_mode
  ),
  inv AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
  ),
  store_ret AS (
    SELECT sr_returned_date_sk, sr_customer_sk, sr_return_amt, sr_net_loss
    FROM store_returns
    WHERE sr_return_quantity > 0
  ),
  web_ret AS (
    SELECT wr_returned_date_sk, wr_refunded_customer_sk, wr_return_amt, wr_net_loss
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  web_pg AS (
    SELECT wp_web_page_sk, wp_url, wp_type, wp_customer_sk
    FROM web_page
  ),
  agg AS (
    SELECT
      d_sold.d_year,
      d_sold.d_month_seq,
      sm.sm_type,
      p.p_promo_name,
      COUNT(*) AS order_count,
      SUM(s.cs_quantity) AS total_quantity,
      SUM(s.cs_ext_sales_price) AS total_sales,
      SUM(s.cs_net_profit) AS total_profit,
      SUM(COALESCE(i.total_on_hand, 0)) AS inventory_on_hand,
      SUM(COALESCE(sr.sr_return_amt, 0)) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_returns
    FROM sales s
    JOIN date_sold d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_ship d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
    JOIN cust_bill cb ON s.cs_bill_customer_sk = cb.c_customer_sk
    JOIN cust_ship cs ON s.cs_ship_customer_sk = cs.c_customer_sk
    JOIN demog_bill db ON s.cs_bill_cdemo_sk = db.cd_demo_sk
    JOIN demog_ship ds ON s.cs_ship_cdemo_sk = ds.cd_demo_sk
    JOIN addr_bill ab ON s.cs_bill_addr_sk = ab.ca_address_sk
    JOIN addr_ship aship ON s.cs_ship_addr_sk = aship.ca_address_sk
    JOIN promo p ON s.cs_promo_sk = p.p_promo_sk
    JOIN ship sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inv i ON s.cs_item_sk = i.inv_item_sk
    LEFT JOIN store_ret sr ON sr.sr_returned_date_sk = d_sold.d_date_sk AND sr.sr_customer_sk = cb.c_customer_sk
    LEFT JOIN web_ret wr ON wr.wr_returned_date_sk = d_sold.d_date_sk AND wr.wr_refunded_customer_sk = cb.c_customer_sk
    LEFT JOIN web_pg wp ON wp.wp_customer_sk = cb.c_customer_sk
    WHERE cb.c_birth_year BETWEEN 1950 AND 1960
    GROUP BY CUBE (d_sold.d_year, d_sold.d_month_seq, sm.sm_type, p.p_promo_name)
    HAVING COUNT(*) > 0
  ),
  missing AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      sm.sm_type,
      p.p_promo_name,
      0 AS order_count,
      0 AS total_quantity,
      0 AS total_sales,
      0 AS total_profit,
      0 AS inventory_on_hand,
      0 AS net_returns
    FROM date_sold d
    CROSS JOIN (SELECT DISTINCT sm_type FROM ship) sm
    CROSS JOIN (SELECT DISTINCT p_promo_name FROM promo) p
    WHERE NOT EXISTS (
      SELECT 1 FROM catalog_sales cs WHERE cs.cs_sold_date_sk = d.d_date_sk
    )
  )
SELECT *
FROM (
  SELECT * FROM agg
  UNION
  SELECT * FROM missing
) combined
EXCEPT
SELECT * FROM agg
ORDER BY d_year DESC, d_month_seq ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
