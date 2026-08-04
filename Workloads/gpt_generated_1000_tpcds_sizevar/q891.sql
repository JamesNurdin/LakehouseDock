WITH site_sales AS (
   SELECT ws.ws_web_site_sk,
          SUM(ws.ws_net_paid) AS site_net_paid,
          COUNT(*) AS site_orders
   FROM web_sales ws
   GROUP BY ws.ws_web_site_sk
)
SELECT
    c_store.c_last_name,
    cd_store.cd_gender,
    t_store.t_hour,
    ss.ss_quantity,
    ss.ss_net_paid,
    wp.wp_url,
    wsite.web_name,
    site_sales.site_net_paid,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_web_page_sk = wp.wp_web_page_sk
    ) AS avg_page_net_paid,
    ROW_NUMBER() OVER (PARTITION BY wsite.web_name ORDER BY ss.ss_net_paid DESC) AS row_num
FROM (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
JOIN time_dim t_store
  ON ss.ss_sold_time_sk = t_store.t_time_sk
JOIN customer c_store
  ON ss.ss_customer_sk = c_store.c_customer_sk
JOIN customer_demographics cd_store
  ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN customer_demographics cd_current
  ON c_store.c_current_cdemo_sk = cd_current.cd_demo_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c_store.c_customer_sk
JOIN web_sales ws
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim t_web
  ON ws.ws_sold_time_sk = t_web.t_time_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN site_sales
  ON site_sales.ws_web_site_sk = wsite.web_site_sk
WHERE cd_store.cd_gender = 'M'
  AND t_store.t_hour BETWEEN 9 AND 17
ORDER BY row_num, c_store.c_last_name
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
