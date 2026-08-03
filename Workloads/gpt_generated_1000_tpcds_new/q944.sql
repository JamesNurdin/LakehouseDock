WITH joined_data AS (
  SELECT
    s.s_store_name AS store_name,
    d.d_year AS year,
    s.s_state AS state,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_mode_type,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    ss.ss_net_paid AS net_paid,
    cr.cr_return_amount AS return_amount,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_quantity AS quantity,
    ss.ss_ext_tax AS ext_tax
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ss.ss_ext_tax > (
      SELECT MAX(ss2.ss_ext_tax)
      FROM store_sales ss2
      WHERE ss2.ss_sold_date_sk = 245090
    )
),
joined_data_alt AS (
  SELECT
    s.s_store_name AS store_name,
    d.d_year AS year,
    s.s_state AS state,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_mode_type,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    ss.ss_net_paid AS net_paid,
    cr.cr_return_amount AS return_amount,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_quantity AS quantity,
    ss.ss_ext_tax AS ext_tax
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'N'
    AND ss.ss_quantity > 5
)
SELECT
  store_name,
  year,
  state,
  promo_name,
  ship_mode_type,
  profit_category,
  SUM(net_paid) AS total_net_paid,
  SUM(return_amount) AS total_return_amount,
  COUNT(DISTINCT ticket_number) AS distinct_transactions,
  AVG(quantity) AS avg_quantity
FROM (
  SELECT * FROM joined_data
  UNION DISTINCT
  SELECT * FROM joined_data_alt
) u
GROUP BY
  store_name,
  year,
  state,
  promo_name,
  ship_mode_type,
  profit_category
ORDER BY total_net_paid DESC
LIMIT 100
