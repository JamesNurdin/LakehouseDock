WITH
    -- Items that have a promotion whose name contains the word 'action' (case‑insensitive)
    -- and whose channel details contain the word 'discount'. Extract the first word for later use.
    promo_items AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            p.p_promo_name,
            p.p_channel_details,
            regexp_extract(p.p_channel_details, '(\\w+)') AS first_word
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        WHERE regexp_like(p.p_promo_name, '(?i)action')
          AND p.p_channel_details LIKE '%discount%'
    ),
    -- Items that appear in web_sales but not in catalog_sales (both filtered on tax > 10)
    item_diff AS (
        SELECT ws.ws_item_sk AS item_sk
        FROM web_sales ws
        WHERE ws.ws_ext_tax > 10
        EXCEPT
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_ext_tax > 10
    ),
    -- Union of sales aggregated by web page (right‑outer join keeps pages without sales)
    -- and by catalog page. Both branches produce the same column list for UNION.
    union_sales AS (
        SELECT
            wp.wp_web_page_id               AS page_id,
            i.i_item_sk                     AS item_sk,
            concat(i.i_brand, ' ', i.i_product_name) AS product_full_name,
            SUM(ws.ws_ext_sales_price)      AS total_sales,
            SUM(ws.ws_net_profit)           AS total_profit,
            COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
            CASE
                WHEN EXISTS (SELECT 1 FROM promo_items pi WHERE pi.i_item_sk = i.i_item_sk) THEN 'Promo'
                ELSE 'NoPromo'
            END                             AS promo_flag
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        RIGHT OUTER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE wp.wp_url LIKE 'http://%example.com%'
          AND regexp_like(wp.wp_url, '^https?://')
        GROUP BY wp.wp_web_page_id, i.i_item_sk, i.i_brand, i.i_product_name
        HAVING SUM(ws.ws_ext_sales_price) > 0
        UNION
        SELECT
            cp.cp_catalog_page_id           AS page_id,
            i.i_item_sk                     AS item_sk,
            concat(i.i_brand, ' ', i.i_product_name) AS product_full_name,
            SUM(cs.cs_ext_sales_price)      AS total_sales,
            SUM(cs.cs_net_profit)           AS total_profit,
            COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
            CASE
                WHEN EXISTS (SELECT 1 FROM promo_items pi WHERE pi.i_item_sk = i.i_item_sk) THEN 'Promo'
                ELSE 'NoPromo'
            END                             AS promo_flag
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_type LIKE 'C%'
        GROUP BY cp.cp_catalog_page_id, i.i_item_sk, i.i_brand, i.i_product_name
        HAVING SUM(cs.cs_ext_sales_price) > 0
    )
SELECT
    us.page_id,
    us.item_sk,
    us.product_full_name,
    us.total_sales,
    us.total_profit,
    us.distinct_customers,
    us.promo_flag
FROM union_sales us
WHERE us.item_sk IN (SELECT item_sk FROM item_diff)
ORDER BY us.total_sales DESC
LIMIT 100
