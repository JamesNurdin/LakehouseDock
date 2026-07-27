WITH inv_filtered AS (
    SELECT inv_date_sk, inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_quantity_on_hand < 10000
)
SELECT
    c.c_customer_id,
    d_sales.d_year,
    ca.ca_state,
    hd.hd_buy_potential,
    p.p_promo_name,
    w.web_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(ss.ss_sales_price) AS min_price,
    MAX(ss.ss_sales_price) AS max_price
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN inv_filtered i
  ON i.inv_date_sk = d_sales.d_date_sk
JOIN web_site w
  ON w.web_open_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
  AND c.c_preferred_cust_flag = 'Y'
  AND ca.ca_state = 'TX'
  AND hd.hd_income_band_sk BETWEEN 5 AND 10
  AND p.p_discount_active = 'Y'
  AND ss.ss_sales_price > 100
  AND w.web_country = 'United States'
GROUP BY
    c.c_customer_id,
    d_sales.d_year,
    ca.ca_state,
    hd.hd_buy_potential,
    p.p_promo_name,
    w.web_name
ORDER BY total_sales DESC
LIMIT 100
