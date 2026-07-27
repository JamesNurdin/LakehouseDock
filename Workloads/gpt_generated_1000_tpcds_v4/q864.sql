WITH cr AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_ship_mode_sk,
    cr.cr_reason_sk
  FROM catalog_returns cr
  WHERE cr.cr_return_amount > 100.00
    AND cr.cr_return_quantity BETWEEN 1 AND 10
),
sm AS (
  SELECT
    sm.sm_ship_mode_sk,
    sm.sm_carrier,
    sm.sm_code,
    sm.sm_type
  FROM ship_mode sm
  WHERE sm.sm_carrier = 'DIAMOND'
    AND sm.sm_code = 'AIR'
),
r AS (
  SELECT
    r.r_reason_sk,
    r.r_reason_desc
  FROM reason r
  WHERE r.r_reason_desc LIKE '%Customer%'
),
sr AS (
  SELECT
    sr.sr_return_time_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_ticket_number,
    sr.sr_reason_sk
  FROM store_returns sr
  WHERE sr.sr_return_time_sk BETWEEN 30000 AND 50000
    AND sr.sr_return_quantity > 0
),
ws AS (
  SELECT
    ws.ws_order_number,
    ws.ws_wholesale_cost,
    ws.ws_net_paid_inc_tax,
    ws.ws_ship_mode_sk,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk,
    ws.ws_coupon_amt
  FROM web_sales ws
  WHERE ws.ws_wholesale_cost > 50.00
    AND ws.ws_net_paid_inc_tax > 500.00
    AND ws.ws_coupon_amt < 100.00
),
wp AS (
  SELECT
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_url
  FROM web_page wp
  WHERE wp.wp_type = 'Content'
),
wsite AS (
  SELECT
    wsite.web_site_sk,
    wsite.web_name,
    wsite.web_country
  FROM web_site wsite
  WHERE wsite.web_country = 'United States'
)
SELECT
  sm.sm_carrier,
  sm.sm_code,
  r.r_reason_desc,
  wsite.web_name,
  wp.wp_type,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
  AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
  MIN(cr.cr_return_quantity) AS min_return_qty,
  MAX(cr.cr_return_quantity) AS max_return_qty
FROM cr
JOIN sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN r ON cr.cr_reason_sk = r.r_reason_sk
JOIN sr ON sr.sr_reason_sk = r.r_reason_sk
JOIN ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN wsite ON ws.ws_web_site_sk = wsite.web_site_sk
GROUP BY
  sm.sm_carrier,
  sm.sm_code,
  r.r_reason_desc,
  wsite.web_name,
  wp.wp_type
ORDER BY total_return_amount DESC
LIMIT 100
