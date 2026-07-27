WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        t.t_time,
        t.t_meal_time,
        cust_ref.c_customer_id AS refunded_customer_id,
        cust_ref.c_birth_country,
        cd_ref.cd_gender AS refunded_gender,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        wp.wp_autogen_flag,
        wp.wp_type,
        ws_site.web_name,
        ws_site.web_gmt_offset
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer cust_bill
        ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        t.t_meal_time IN ('lunch', 'dinner')
        AND t.t_hour BETWEEN 8 AND 18
        AND cust_ref.c_birth_country IN ('MEXICO', 'KOREA')
        AND cd_ref.cd_gender = 'F'
        AND wp.wp_autogen_flag = 'N'
        AND ws.ws_ext_sales_price > 100
        AND ws_site.web_gmt_offset BETWEEN -5 AND 5
)
SELECT
    refunded_customer_id,
    t_meal_time,
    wp_type,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales_price,
    AVG(CASE WHEN ws_net_profit > 0 THEN ws_net_profit ELSE 0 END) AS avg_positive_profit,
    COUNT(*) AS txn_count,
    (SELECT COUNT(*) FROM web_page wp2 WHERE wp2.wp_type = base.wp_type) AS same_type_page_cnt
FROM base
GROUP BY refunded_customer_id, t_meal_time, wp_type
HAVING SUM(cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
