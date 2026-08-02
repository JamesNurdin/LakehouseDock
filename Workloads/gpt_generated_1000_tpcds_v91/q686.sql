WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d_sales_filter ON ss.ss_sold_date_sk = d_sales_filter.d_date_sk
    JOIN time_dim t_sales_filter ON ss.ss_sold_time_sk = t_sales_filter.t_time_sk
    WHERE d_sales_filter.d_year = 2001
      AND t_sales_filter.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_customer_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date,
    t_sales.t_hour,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    r_cat.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    ws.ws_net_paid,
    wr.wr_return_amt,
    sales_agg.total_net_paid,
    sales_agg.sales_cnt,
    SUM(sales_agg.total_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d_sales.d_date ROWS UNBOUNDED PRECEDING) AS cumulative_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_sales.d_date DESC) AS rn,
    LAG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d_sales.d_date) AS prev_ws_net_paid,
    (SELECT MAX(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk) AS max_refund_amount
FROM sales_agg
JOIN date_dim d_sales ON sales_agg.sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON sales_agg.sold_time_sk = t_sales.t_time_sk
JOIN customer c ON sales_agg.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_sold_date_sk = d_sales.d_date_sk
    AND ws.ws_sold_time_sk = t_sales.t_time_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
    AND wr.wr_returned_time_sk = t_sales.t_time_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN date_dim d_ws_open ON wsite.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON wsite.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    ib.ib_lower_bound >= 40000
    AND r_cat.r_reason_desc = 'Did not like the color'
    AND wp.wp_type = 'home'
    AND wsite.web_country = 'United States'
ORDER BY
    c.c_customer_id,
    d_sales.d_date DESC
LIMIT 100
