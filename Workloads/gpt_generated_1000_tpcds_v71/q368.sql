WITH sales_filtered AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        i.i_item_desc AS item_desc,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, 'Premium')
      AND p.p_promo_name LIKE '%Holiday%'
)
SELECT
    CONCAT(first_name, ' ', last_name) AS customer_name,
    SUM(net_profit) AS total_net_profit,
    COUNT(DISTINCT item_sk) AS distinct_items
FROM sales_filtered sf
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_refunded_customer_sk = sf.customer_sk
      AND cr.cr_item_sk = sf.item_sk
)
GROUP BY CONCAT(first_name, ' ', last_name)
ORDER BY total_net_profit DESC
LIMIT 100
