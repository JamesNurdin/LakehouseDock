WITH sub1 AS (
   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_net_paid AS net_amount,
     d.d_year AS year,
     p.p_promo_name AS promo_name,
     wp.wp_url AS page_url
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE p.p_channel_dmail = 'Y'
     AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
sub2 AS (
   SELECT
     sr.sr_ticket_number AS order_number,
     sr.sr_net_loss AS net_amount,
     d.d_year AS year,
     r.r_reason_desc AS promo_name,
     CAST(NULL AS varchar) AS page_url
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%damaged%'
     AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
  u.order_number,
  u.net_amount,
  u.year,
  u.promo_name,
  u.page_url
FROM (
   SELECT * FROM sub1
   UNION ALL
   SELECT * FROM sub2
) AS u
WHERE EXISTS (
   SELECT 1
   FROM inventory i
   JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
   WHERE d2.d_year = u.year
     AND i.inv_quantity_on_hand > 0
)
  AND u.net_amount > (
    SELECT AVG(ws2.ws_net_paid)
    FROM web_sales ws2
    WHERE ws2.ws_sold_date_sk IN (
        SELECT d3.d_date_sk FROM date_dim d3 WHERE d3.d_year = 2001
    )
  )
ORDER BY u.net_amount DESC, u.order_number
LIMIT 100
