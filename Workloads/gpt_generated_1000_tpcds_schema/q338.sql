WITH diff_orders AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
sales_base AS (
    SELECT
        wsite.web_site_sk AS web_site_sk,
        wsite.web_state,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_customer_sk,
        i.i_category,
        i.i_brand,
        c.c_birth_month,
        wp.wp_type,
        prod_prefix.prod_prefix
    FROM web_sales ws
    RIGHT OUTER JOIN web_site wsite
        ON wsite.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN item i
        ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN customer c
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
    CROSS JOIN LATERAL (
        SELECT substr(i.i_product_name, 1, 3) AS prod_prefix
    ) AS prod_prefix
    WHERE
        ws.ws_ext_sales_price > 1000
        AND ws.ws_quantity >= 1
        AND i.i_current_price BETWEEN 10 AND 5000
        AND c.c_birth_month IN (1, 5, 7, 12)
        AND wp.wp_char_count > 1000
        AND wsite.web_state = 'CA'
        AND ws.ws_order_number IN (SELECT ws_order_number FROM diff_orders)
),
agg1 AS (
    SELECT
        web_site_sk,
        web_state,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS orders_cnt,
        COUNT(DISTINCT ws_bill_customer_sk) AS customers_cnt,
        AVG(ws_quantity) AS avg_quantity
    FROM sales_base
    GROUP BY web_site_sk, web_state
),
final AS (
    SELECT
        a.web_site_sk,
        a.web_state,
        a.total_sales,
        a.total_profit,
        a.orders_cnt,
        a.customers_cnt,
        a.avg_quantity,
        (SELECT AVG(total_sales) FROM agg1) AS avg_sales_across_sites
    FROM agg1 a
    WHERE a.total_sales > (SELECT AVG(total_sales) FROM agg1) * 1.2
)
SELECT *
FROM final
ORDER BY total_sales DESC
LIMIT 100
