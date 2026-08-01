WITH ws_join AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        c.c_customer_id,
        c.c_customer_sk,
        wp.wp_web_page_sk,
        wp.wp_url,
        t.t_time_sk,
        t.t_am_pm,
        t.t_time,
        t.t_hour,
        t.t_minute
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_rec_end_date = DATE '2000-09-02'
      AND t.t_am_pm = 'PM'
      AND t.t_time = 10
),
cr_join AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        c.c_customer_id,
        c.c_customer_sk,
        t.t_time_sk,
        t.t_am_pm,
        t.t_time
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND t.t_time = 10
),
sales_agg AS (
    SELECT
        ws.c_customer_id,
        ws.t_time AS sale_time,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt,
        MAX(ws.ws_net_profit) AS max_profit
    FROM ws_join ws
    GROUP BY ws.c_customer_id, ws.t_time
),
returns_agg AS (
    SELECT
        cr.c_customer_id,
        cr.t_time AS return_time,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM cr_join cr
    GROUP BY cr.c_customer_id, cr.t_time
)
SELECT
    cs.c_customer_id,
    cs.sale_time,
    cs.total_sales,
    cs.total_tax,
    cs.sales_cnt,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    ) AS avg_net_profit,
    dl.total_discount
FROM sales_agg cs
LEFT JOIN returns_agg cr_agg
    ON cs.c_customer_id = cr_agg.c_customer_id
    AND cs.sale_time = cr_agg.return_time
JOIN customer c
    ON cs.c_customer_id = c.c_customer_id
CROSS JOIN LATERAL (
    SELECT SUM(ws3.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws3
    WHERE ws3.ws_bill_customer_sk = c.c_customer_sk
      AND ws3.ws_web_page_sk IN (
          SELECT wp.wp_web_page_sk
          FROM web_page wp
          WHERE wp.wp_autogen_flag = 'N'
            AND wp.wp_rec_end_date = DATE '2000-09-02'
      )
) AS dl
CROSS JOIN (VALUES (1), (2), (3)) AS v(dummy)
WHERE cs.total_sales > 0
ORDER BY cs.total_sales DESC
LIMIT 100
