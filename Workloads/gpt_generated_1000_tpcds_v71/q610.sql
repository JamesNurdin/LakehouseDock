WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        c.c_customer_id,
        ws.ws_web_site_sk AS web_site_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    WHERE
        wsite.web_city = 'Georgetown'
        AND wsite.web_company_id = 3
        AND c.c_birth_year BETWEEN 1970 AND 1985
        AND ws.ws_ext_wholesale_cost > 1000
    GROUP BY i.i_item_id, i.i_category, c.c_customer_id, ws.ws_web_site_sk
)
SELECT
    i_item_id,
    i_category,
    c_customer_id,
    web_site_sk,
    web_sales_amount,
    store_sales_amount,
    (web_sales_amount + store_sales_amount) AS total_sales,
    web_orders,
    store_tickets,
    CASE
        WHEN web_sales_amount > store_sales_amount THEN 'Web Dominant'
        ELSE 'Store Dominant'
    END AS sales_channel
FROM sales_agg
WHERE (web_sales_amount + store_sales_amount) > (
    SELECT AVG(web_sales_amount + store_sales_amount) FROM sales_agg
)
ORDER BY total_sales DESC
LIMIT 100
