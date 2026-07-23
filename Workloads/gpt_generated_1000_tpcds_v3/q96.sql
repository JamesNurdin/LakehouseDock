WITH avg_profit AS (
    SELECT AVG(ws_net_profit) AS overall_avg_profit
    FROM web_sales
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    ws.ws_sold_date_sk,
    CONCAT('Item ', i.i_item_id, ': ', i.i_product_name) AS item_label,
    COUNT(*) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) > (SELECT overall_avg_profit FROM avg_profit) THEN 'Above Avg'
        WHEN SUM(ws.ws_net_profit) > (SELECT overall_avg_profit FROM avg_profit) * 0.5 THEN 'Medium'
        ELSE 'Below Avg'
    END AS profit_category,
    MAX(p.p_promo_name) FILTER (WHERE p.p_promo_name IS NOT NULL) AS promo_name,
    MAX(ws_site.web_name) AS web_site_name
FROM
    web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN avg_profit
WHERE
    REGEXP_LIKE(i.i_item_desc, '(?i)deluxe|premium')
    AND wp.wp_url LIKE '%sale%'
    AND cd.cd_gender = 'M'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_return_quantity > 0
          AND REGEXP_LIKE(CAST(wr.wr_reason_sk AS varchar), '^[0-9]+$')
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    ws.ws_sold_date_sk,
    ws_site.web_name
ORDER BY
    total_net_profit DESC
LIMIT 100
