WITH ws AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_customer_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        ws_net_paid_inc_ship_tax,
        ws_coupon_amt
    FROM tpcds.web_sales
    WHERE ws_net_paid_inc_ship_tax > 5000
),
joined AS (
    SELECT
        ws.ws_order_number,
        d.d_year,
        d.d_month_seq,
        t.t_am_pm,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        wp.wp_type,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_coupon_amt,
        sr.sr_net_loss        AS sr_net_loss,
        sr.sr_return_quantity AS sr_return_quantity
    FROM ws
    JOIN tpcds.date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsite   ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN tpcds.store_returns sr
          ON sr.sr_returned_date_sk = d.d_date_sk
         AND sr.sr_return_time_sk  = t.t_time_sk
         AND sr.sr_customer_sk     = c.c_customer_sk
    WHERE d.d_year = 2002
      AND t.t_am_pm = 'PM'
      AND wsite.web_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_type = 'Content'
)
SELECT
    d_year,
    d_month_seq,
    t_am_pm,
    c_first_name,
    c_last_name,
    wp_type,
    COUNT(DISTINCT ws_order_number)               AS orders_cnt,
    SUM(ws_net_paid_inc_ship_tax)                 AS total_sales,
    AVG(ws_coupon_amt)                            AS avg_coupon,
    SUM(COALESCE(sr_net_loss, 0))                 AS total_return_loss,
    MAX(sr_return_quantity)                       AS max_return_qty
FROM joined
GROUP BY d_year, d_month_seq, t_am_pm, c_first_name, c_last_name, wp_type
ORDER BY total_sales DESC
LIMIT 100
