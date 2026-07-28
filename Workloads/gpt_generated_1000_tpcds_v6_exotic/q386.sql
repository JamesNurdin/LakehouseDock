WITH sales_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        c.c_email_address,
        i.i_item_desc,
        i.i_product_name,
        i.i_item_id,
        d.d_year,
        d.d_month_seq,
        wp.wp_url,
        wsit.web_country
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE regexp_like(i.i_item_desc, '(?i)family')
      AND wp.wp_url LIKE '%.com%'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND wsit.web_country = 'United States'
)
SELECT
    d_year,
    d_month_seq AS month,
    i_product_name,
    CONCAT(i_item_id, '-', CAST(d_month_seq AS VARCHAR)) AS product_month_key,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS distinct_orders
FROM sales_filtered
GROUP BY d_year, d_month_seq, i_product_name, i_item_id
ORDER BY total_net_profit DESC
LIMIT 100
