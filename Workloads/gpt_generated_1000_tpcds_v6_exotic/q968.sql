WITH
  sales_agg AS (
    SELECT
      ss_addr_sk,
      ss_sold_date_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_quantity) AS total_qty
    FROM store_sales
    WHERE ss_net_paid > 0
    GROUP BY ss_addr_sk, ss_sold_date_sk
  ),
  carrier_set AS (
    SELECT sm_carrier FROM ship_mode WHERE sm_type = 'OVERNIGHT'
    UNION
    SELECT sm_carrier FROM ship_mode WHERE sm_type = 'REGULAR'
  )
SELECT
  ca_sales.ca_state,
  sm.sm_type,
  d_sales.d_year,
  SUM(sa.total_net_paid) AS agg_net_paid,
  COUNT(DISTINCT cr.cr_order_number) AS return_orders,
  MAX(wp.wp_char_count) AS max_page_chars,
  (
    SELECT MAX(wp2.wp_char_count)
    FROM web_page wp2
    WHERE wp2.wp_type = 'Landing'
  ) AS max_landing_char
FROM sales_agg sa
JOIN date_dim d_sales ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_address ca_sales ON sa.ss_addr_sk = ca_sales.ca_address_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE sm.sm_carrier IN (SELECT sm_carrier FROM carrier_set)
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_type = 'Home'
          AND wp2.wp_char_count > 10000
          AND wp2.wp_web_page_sk = wp.wp_web_page_sk
      )
GROUP BY ca_sales.ca_state, sm.sm_type, d_sales.d_year
HAVING SUM(sa.total_net_paid) > 100000
ORDER BY agg_net_paid DESC
LIMIT 100
