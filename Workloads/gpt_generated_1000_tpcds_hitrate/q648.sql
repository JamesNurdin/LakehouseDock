WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_date,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_item_desc,
        w.w_warehouse_name,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i).*([aeiou]{3,}).*')
      AND w.w_zip LIKE '42%'
)
SELECT
    cs.c_customer_id,
    cs.d_date,
    cs.i_item_id,
    cs.i_item_desc,
    cs.w_warehouse_name,
    CONCAT(cs.c_customer_id, '_', cs.i_item_id) AS cust_item_key,
    CASE
        WHEN cs.ws_net_profit > 0 THEN 'PROFIT'
        WHEN cs.ws_net_profit = 0 THEN 'BREAK_EVEN'
        ELSE 'LOSS'
    END AS profit_flag,
    SUM(cs.ws_ext_sales_price) OVER (
        PARTITION BY cs.c_customer_id
        ORDER BY cs.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales,
    LAG(cs.ws_ext_sales_price) OVER (
        PARTITION BY cs.c_customer_id
        ORDER BY cs.d_date
    ) AS prev_sale_amount,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.ws_order_number
    ) AS return_count,
    CASE
        WHEN regexp_extract(wp.wp_url, '://([^/]+)', 1) = 'example.com' THEN 'EXAMPLE'
        ELSE 'OTHER'
    END AS domain_category
FROM customer_sales cs
JOIN web_page wp ON cs.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_url LIKE '%product%'
ORDER BY cs.d_date DESC
LIMIT 100
