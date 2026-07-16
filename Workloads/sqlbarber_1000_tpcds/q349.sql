SELECT date_dim.d_year,
       web_page.wp_type,
       web_site.web_name,
       SUM(ws_sub.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT ws_sub.ws_order_number) AS distinct_orders
FROM (
    SELECT ws_sold_date_sk,
           ws_web_page_sk,
           ws_web_site_sk,
           ws_net_paid,
           ws_order_number
    FROM web_sales
    WHERE ws_quantity > 100
) AS ws_sub
JOIN date_dim
  ON ws_sub.ws_sold_date_sk = date_dim.d_date_sk
JOIN web_page
  ON ws_sub.ws_web_page_sk = web_page.wp_web_page_sk
JOIN web_site
  ON ws_sub.ws_web_site_sk = web_site.web_site_sk
GROUP BY date_dim.d_year,
         web_page.wp_type,
         web_site.web_name
HAVING SUM(ws_sub.ws_net_paid) > 1718.40
