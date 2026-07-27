SELECT
  wsit.web_site_id,
  wsit.web_name,
  d_sold.d_year,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  COUNT(DISTINCT ws.ws_order_number) AS orders,
  RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
  CASE
    WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High'
    ELSE 'Medium'
  END AS sales_category
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_sold.d_date_sk
  AND sr.sr_cdemo_sk = cd.cd_demo_sk
  AND sr.sr_addr_sk = ca.ca_address_sk
WHERE d_sold.d_year = 2001
  AND ca.ca_state = 'CA'
  AND sr.sr_return_quantity > 10
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_discount_active = 'Y'
          AND p.p_start_date_sk <= d_sold.d_date_sk
          AND p.p_end_date_sk >= d_sold.d_date_sk
      )
GROUP BY
  wsit.web_site_id,
  wsit.web_name,
  d_sold.d_year
ORDER BY total_profit DESC
LIMIT 100
