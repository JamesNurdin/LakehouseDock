WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_net_paid)            AS total_net_paid,
        SUM(ws.ws_net_profit)          AS total_net_profit,
        AVG(ws.ws_ext_discount_amt)    AS avg_discount,
        COUNT(*)                       AS cnt_items
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        cd_bill.cd_gender = 'M'
        AND cd_bill.cd_marital_status = 'M'
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_max_ad_count <= 2
        AND td.t_hour BETWEEN 9 AND 17
        AND ws.ws_promo_sk IN (202, 906)
    GROUP BY
        ws.ws_order_number,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    td.t_shift,
    COUNT(DISTINCT sa.ws_order_number)                         AS num_orders,
    SUM(sa.total_net_paid)                                      AS sum_net_paid,
    SUM(sa.total_net_profit)                                    AS sum_net_profit,
    AVG(sa.avg_discount)                                        AS overall_avg_discount,
    SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT CASE WHEN wp2.wp_autogen_flag = 'N' THEN wp2.wp_web_page_sk END) AS num_web_pages_N_flag
FROM sales_agg sa
JOIN customer_demographics cd ON sa.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td ON sa.ws_sold_time_sk = td.t_time_sk
LEFT JOIN web_page wp2 ON sa.ws_web_page_sk = wp2.wp_web_page_sk
LEFT JOIN store_returns sr ON sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_order_number = sa.ws_order_number
WHERE
    td.t_shift = 'DAY'
    AND cd.cd_credit_rating = 'Excellent'
    AND cd.cd_dep_count >= 2
    AND sr.sr_return_quantity > 0
    AND wr.wr_net_loss > 100.00
    AND wp2.wp_max_ad_count <= 3
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    td.t_shift
HAVING
    SUM(sa.total_net_paid) > 1000
ORDER BY
    total_return_loss DESC
LIMIT 100
