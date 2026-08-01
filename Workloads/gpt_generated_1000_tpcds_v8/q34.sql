WITH base AS (
    SELECT
        i.i_category,
        i.i_brand,
        sm.sm_type,
        td.t_hour,
        hd.hd_income_band_sk,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ws.ws_net_profit,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        ws.ws_quantity,
        ws.ws_sold_date_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_customer_sk = c_refund.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c_refund.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c_refund.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE i.i_category = 'Sports'
      AND sm.sm_type = 'AIR'
      AND td.t_hour BETWEEN 8 AND 12
      AND hd.hd_income_band_sk = 10
      AND ws.ws_quantity > 5
      AND cr.cr_return_quantity > 0
)
SELECT
    i_category,
    sm_type,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(ws_net_profit) AS sum_net_profit,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(total_return_amount) DESC) AS rn
FROM (
    SELECT
        i_category,
        sm_type,
        (COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_return_amount,
        ws_net_profit,
        ws_sold_date_sk
    FROM base
    WHERE ws_net_profit > (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = base.ws_sold_date_sk
    )
) AS agg
GROUP BY GROUPING SETS (
    (i_category, sm_type),
    (i_category),
    (sm_type),
    ()
)
HAVING SUM(total_return_amount) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100
