WITH store_union AS (
   SELECT
       'store' AS channel_type,
       s.s_store_id AS channel_id,
       ss.ss_net_paid AS sales_amount
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2002
     AND p.p_channel_press = 'Y'
),
web_union AS (
   SELECT
       'web' AS channel_type,
       wp.wp_url AS channel_id,
       ws.ws_net_paid AS sales_amount
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2002
     AND wp.wp_type = 'home'
     AND p.p_channel_press = 'Y'
)
SELECT
    channel_type,
    channel_id,
    SUM(sales_amount) AS total_sales
FROM (
    SELECT * FROM store_union
    UNION ALL
    SELECT * FROM web_union
) AS combined
GROUP BY GROUPING SETS (
    (channel_type, channel_id),
    (channel_type),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
