WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        i.i_manufact,
        i.i_item_desc,
        p.p_promo_name,
        c.c_email_address
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '\\bPack\\b')
      AND p.p_promo_name LIKE 'Holiday%'
      AND regexp_like(c.c_email_address, '@.+\\.com')
)
SELECT
    f.i_manufact,
    COUNT(*) AS sales_count,
    SUM(f.ws_net_profit) AS total_profit,
    CONCAT('Manufacturer ', CAST(f.i_manufact AS varchar)) AS manufact_label,
    REGEXP_EXTRACT(MIN(f.c_email_address), '@([^.]*)\\.', 1) AS sample_domain
FROM filtered_sales f
GROUP BY f.i_manufact
HAVING SUM(f.ws_net_profit) > 10000
   AND EXISTS (
        SELECT 1
        FROM item i3
        WHERE i3.i_manufact = f.i_manufact
          AND regexp_like(i3.i_item_desc, 'Premium')
    )
ORDER BY total_profit DESC
LIMIT 10
