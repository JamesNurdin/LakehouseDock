WITH sales_with_url AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_sold_date_sk,
        i.i_category,
        i.i_product_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        wp.wp_url,
        regexp_like(wp.wp_url, '^https?://.*sale.*$') AS is_sale_page,
        regexp_extract(wp.wp_url, '://([^/]+)/', 1) AS domain,
        substring(wp.wp_url, 1, 30) AS url_prefix
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*sale.*$')
)
SELECT DISTINCT
    swu.customer_name,
    swu.i_category,
    swu.domain,
    swu.url_prefix,
    swu.ws_order_number,
    swu.ws_net_paid,
    swu.ws_quantity,
    swu.i_product_name,
    swu.is_sale_page,
    (SELECT avg(ws2.ws_net_paid)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = swu.ws_item_sk) AS avg_net_paid_for_item,
    ROW_NUMBER() OVER (PARTITION BY swu.i_category ORDER BY swu.ws_net_paid DESC) AS rank_in_category
FROM sales_with_url swu
WHERE EXISTS (
    SELECT 1
    FROM customer_demographics cd
    WHERE cd.cd_demo_sk = swu.ws_bill_cdemo_sk
      AND cd.cd_credit_rating = 'Excellent'
)
ORDER BY swu.ws_net_paid DESC, swu.customer_name
LIMIT 100
