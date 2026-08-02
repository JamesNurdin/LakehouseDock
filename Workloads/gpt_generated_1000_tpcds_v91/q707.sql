WITH brand_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_brand,
           i_product_name
    FROM   item
    WHERE  i_brand_id IN (3003001, 6016006)
),
union_sales AS (
    SELECT
        c.c_customer_id                               AS customer_id,
        i.i_item_id                                   AS item_id,
        'store'                                        AS channel,
        SUM(ss.ss_net_paid)                           AS total_net_paid,
        (SELECT AVG(ss2.ss_net_paid)
         FROM   store_sales ss2
         WHERE  ss2.ss_item_sk = i.i_item_sk)       AS avg_item_net_paid,
        (SELECT COUNT(*)
         FROM   store_sales ss3
         WHERE  ss3.ss_customer_sk = c.c_customer_sk
           AND  ss3.ss_item_sk = i.i_item_sk
           AND  ss3.ss_net_paid > 0)                AS cust_item_purchase_count,
        CAST(NULL AS integer)                         AS distinct_url_segments
    FROM   store_sales ss
    JOIN   brand_items i
           ON ss.ss_item_sk = i.i_item_sk
    JOIN   customer c
           ON ss.ss_customer_sk = c.c_customer_sk
    WHERE  c.c_birth_month = 11
      AND  ss.ss_net_paid > 1000
      AND EXISTS (SELECT 1
                  FROM   web_sales ws2
                  WHERE  ws2.ws_bill_customer_sk = c.c_customer_sk
                    AND  ws2.ws_net_paid > 2000)
    GROUP BY c.c_customer_id,
             i.i_item_id,
             c.c_customer_sk,
             i.i_item_sk

    UNION ALL

    SELECT
        c.c_customer_id                               AS customer_id,
        i.i_item_id                                   AS item_id,
        'web'                                          AS channel,
        SUM(ws.ws_net_paid)                           AS total_net_paid,
        (SELECT AVG(ws2.ws_net_paid)
         FROM   web_sales ws2
         WHERE  ws2.ws_item_sk = i.i_item_sk)       AS avg_item_net_paid,
        (SELECT COUNT(*)
         FROM   web_sales ws2
         WHERE  ws2.ws_bill_customer_sk = c.c_customer_sk
           AND  ws2.ws_item_sk = i.i_item_sk
           AND  ws2.ws_net_paid > 0)                AS cust_item_purchase_count,
        COUNT(DISTINCT seg)                           AS distinct_url_segments
    FROM   web_sales ws
    JOIN   brand_items i
           ON ws.ws_item_sk = i.i_item_sk
    JOIN   customer c
           ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN   web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(SPLIT(wp.wp_url, '/')) AS t(seg)
    WHERE  c.c_birth_month = 11
      AND  ws.ws_net_paid > 1000
      AND EXISTS (SELECT 1
                  FROM   store_sales ss2
                  WHERE  ss2.ss_customer_sk = c.c_customer_sk
                    AND  ss2.ss_net_paid > 2000)
    GROUP BY c.c_customer_id,
             i.i_item_id,
             c.c_customer_sk,
             i.i_item_sk
)
SELECT
    customer_id,
    item_id,
    channel,
    total_net_paid,
    avg_item_net_paid,
    cust_item_purchase_count,
    distinct_url_segments
FROM   union_sales
ORDER BY total_net_paid DESC,
         customer_id
LIMIT 100
