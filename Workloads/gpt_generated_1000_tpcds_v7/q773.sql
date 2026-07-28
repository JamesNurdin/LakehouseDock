WITH store_agg AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_net_paid) AS metric,
           'store' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND i.i_brand = 'callyeingeing'
    GROUP BY c.c_customer_id
),
web_agg AS (
    SELECT c.c_customer_id,
           COUNT(wp.wp_web_page_id) AS metric,
           'web' AS source
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND wp.wp_type = 'article'
    GROUP BY c.c_customer_id
)
SELECT c_customer_id,
       metric,
       source
FROM store_agg
UNION ALL
SELECT c_customer_id,
       metric,
       source
FROM web_agg
ORDER BY c_customer_id, source
