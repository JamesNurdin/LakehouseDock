WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_product_name,
           i_brand,
           regexp_extract(i_item_desc, '([0-9]{3})', 1) AS code
    FROM item
    WHERE regexp_like(i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND i_product_name LIKE '%Gold%'
)
SELECT *
FROM (
    SELECT 'store' AS channel,
           s.s_store_name AS location,
           i.i_brand,
           i.code,
           SUM(ss.ss_net_paid) AS total_paid
    FROM filtered_items i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_item_sk = i.i_item_sk
    )
    GROUP BY s.s_store_name, i.i_brand, i.code
    HAVING SUM(ss.ss_net_paid) > 10000

    UNION ALL

    SELECT 'web' AS channel,
           wp.wp_type AS location,
           i.i_brand,
           i.code,
           SUM(ws.ws_net_paid) AS total_paid
    FROM filtered_items i
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
          AND wr.wr_item_sk = i.i_item_sk
    )
    GROUP BY wp.wp_type, i.i_brand, i.code
    HAVING SUM(ws.ws_net_paid) > 15000
) AS combined
ORDER BY total_paid DESC
LIMIT 100
