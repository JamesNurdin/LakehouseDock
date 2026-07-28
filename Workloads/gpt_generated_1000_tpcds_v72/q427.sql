WITH
  store_agg AS (
    SELECT
      p.p_promo_id                                   AS promo_id,
      p.p_promo_name                                AS promo_name,
      cd.cd_gender                                   AS gender,
      NULL                                           AS carrier,
      NULL                                           AS sold_date_sk,
      SUM(ss.ss_ext_sales_price)                    AS sales_amount,
      COUNT(*)                                      AS sales_cnt,
      'store'                                        AS sales_channel,
      NULL                                           AS order_number,
      c.c_customer_sk                               AS customer_sk,
      ca.ca_city                                    AS city,
      cd.cd_education_status                        AS education_status,
      NULL                                           AS web_name,
      NULL                                           AS wp_type
    FROM store_sales ss
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk   = ca.ca_address_sk
    JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
      ca.ca_street_type   = 'Avenue'
      AND cd.cd_gender    = 'M'
      AND p.p_discount_active = 'Y'
      AND c.c_birth_country = 'JAPAN'
    GROUP BY
      p.p_promo_id,
      p.p_promo_name,
      cd.cd_gender,
      c.c_customer_sk,
      ca.ca_city,
      cd.cd_education_status
    HAVING SUM(ss.ss_ext_sales_price) > 10000
  ),

  web_agg AS (
    SELECT
      p.p_promo_id                                   AS promo_id,
      p.p_promo_name                                AS promo_name,
      NULL                                           AS gender,
      sm.sm_carrier                                 AS carrier,
      ws.ws_sold_date_sk                            AS sold_date_sk,
      SUM(ws.ws_ext_sales_price)                    AS sales_amount,
      COUNT(*)                                      AS sales_cnt,
      'web'                                          AS sales_channel,
      ws.ws_order_number                            AS order_number,
      c.c_customer_sk                               AS customer_sk,
      ca.ca_city                                    AS city,
      cd.cd_education_status                        AS education_status,
      wsite.web_name                                AS web_name,
      wp.wp_type                                    AS wp_type
    FROM web_sales ws
    JOIN promotion p               ON ws.ws_promo_sk   = p.p_promo_sk
    JOIN ship_mode sm              ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite            ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca       ON ws.ws_bill_addr_sk   = ca.ca_address_sk
    JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
      sm.sm_carrier           = 'UPS'
      AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND cd.cd_gender        = 'F'
      AND wsite.web_country   = 'United States'
      AND c.c_birth_country   = 'JAPAN'
    GROUP BY
      p.p_promo_id,
      p.p_promo_name,
      sm.sm_carrier,
      ws.ws_sold_date_sk,
      ws.ws_order_number,
      c.c_customer_sk,
      ca.ca_city,
      cd.cd_education_status,
      wsite.web_name,
      wp.wp_type
    HAVING COUNT(*) >= 5
  ),

  combined_sales AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )

SELECT
  cs.sales_channel,
  cs.promo_id,
  cs.promo_name,
  SUM(cs.sales_amount)               AS total_sales_amount,
  AVG(cs.sales_amount)               AS avg_sales_amount,
  COUNT(*)                           AS num_records,
  MIN(cs.sales_amount)               AS min_sales_amount,
  MAX(cs.sales_amount)               AS max_sales_amount,
  (SELECT SUM(sales_amount) FROM combined_sales) AS overall_sales_amount
FROM combined_sales cs
WHERE
  (cs.sales_channel = 'web' AND EXISTS (
       SELECT 1
       FROM web_returns wr
       WHERE wr.wr_order_number = cs.order_number
         AND wr.wr_return_amt > 0
   ))
  OR cs.sales_channel = 'store'
GROUP BY
  cs.sales_channel,
  cs.promo_id,
  cs.promo_name
HAVING SUM(cs.sales_amount) > 50000
ORDER BY total_sales_amount DESC
LIMIT 100
