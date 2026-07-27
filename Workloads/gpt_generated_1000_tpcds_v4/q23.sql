WITH filtered_sales AS (
   SELECT
       ws.ws_bill_customer_sk,
       ws.ws_net_paid,
       ws.ws_net_profit,
       ws.ws_web_page_sk,
       d.d_year,
       d.d_date,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       wp.wp_url
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2022
     AND regexp_like(wp.wp_url, 'promo[0-9]+')
     AND c.c_email_address LIKE '%@example.com'
)
SELECT DISTINCT
   agg.c_id,
   agg.full_name,
   agg.email_domain,
   agg.total_net_paid,
   agg.total_net_profit,
   agg.avg_daily_net_paid,
   agg.rank_by_paid,
   agg.paid_vs_avg
FROM (
   SELECT
       f.c_customer_id AS c_id,
       concat(f.c_first_name, ' ', f.c_last_name) AS full_name,
       regexp_extract(f.c_email_address, '@(.*)$', 1) AS email_domain,
       sum(f.ws_net_paid) AS total_net_paid,
       sum(f.ws_net_profit) AS total_net_profit,
       sum(f.ws_net_paid) / count(DISTINCT f.d_date) AS avg_daily_net_paid,
       ROW_NUMBER() OVER (ORDER BY sum(f.ws_net_paid) DESC) AS rank_by_paid,
       sum(f.ws_net_paid) / (
           SELECT avg(ws2.ws_net_paid)
           FROM web_sales ws2
           JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
           WHERE d2.d_year = 2022
       ) AS paid_vs_avg
   FROM filtered_sales f
   WHERE EXISTS (
       SELECT 1
       FROM store_returns sr
       JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
       WHERE sr.sr_customer_sk = f.ws_bill_customer_sk
         AND dr.d_year = 2022
   )
   GROUP BY f.c_customer_id, f.c_first_name, f.c_last_name, f.c_email_address
) agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
