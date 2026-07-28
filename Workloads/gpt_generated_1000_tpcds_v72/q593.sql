WITH
    filtered_items AS (
        SELECT i_item_sk,
               i_product_name,
               i_formulation,
               i_manager_id
        FROM item
        WHERE regexp_like(i_formulation, '^\\d{3}[a-z]+\\d+$')
    ),
    agg_sales AS (
        SELECT
            c.c_customer_id,
            c.c_email_address,
            c.c_customer_sk,
            COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
            SUM(ws.ws_ext_sales_price)          AS total_sales,
            SUM(ws.ws_net_profit)               AS total_net_profit,
            ws.ws_web_page_sk,
            wp.wp_rec_start_date,
            td.t_hour
        FROM web_sales ws
        JOIN filtered_items fi        ON ws.ws_item_sk = fi.i_item_sk
        JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN time_dim td              ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
          AND td.t_hour BETWEEN 9 AND 17
        GROUP BY
            c.c_customer_id,
            c.c_email_address,
            c.c_customer_sk,
            ws.ws_web_page_sk,
            wp.wp_rec_start_date,
            td.t_hour
    )
SELECT
    a.c_customer_id,
    a.c_email_address,
    a.orders_cnt,
    a.total_sales,
    COALESCE(
        (SELECT SUM(wr.wr_return_amt)
         FROM web_returns wr
         WHERE wr.wr_refunded_customer_sk = a.c_customer_sk),
        0)                                 AS total_return_amt,
    a.total_net_profit,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank,
    url_parts.domain
FROM agg_sales a
JOIN web_page wp
  ON a.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
) AS url_parts
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_refunded_customer_sk = a.c_customer_sk
      AND r.r_reason_desc LIKE '%not%'
)
ORDER BY a.total_sales DESC
LIMIT 100
