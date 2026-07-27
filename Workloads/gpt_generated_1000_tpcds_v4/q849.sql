WITH joined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        w.w_warehouse_id,
        w.w_state,
        t.t_hour,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        cr.cr_net_loss,
        sr.sr_net_loss,
        ss.ss_net_profit,
        c.c_customer_id
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd.hd_income_band_sk IN (4, 8)
      AND ss.ss_sales_price > 20
)
SELECT
    cc_call_center_id,
    w_warehouse_id,
    t_hour,
    hd_income_band_sk,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(ss_net_profit) AS total_sales_profit,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM joined
GROUP BY
    cc_call_center_id,
    w_warehouse_id,
    t_hour,
    hd_income_band_sk
ORDER BY total_catalog_net_loss DESC
LIMIT 100
