WITH joined AS (
    SELECT
        cc.cc_name,
        i.i_brand,
        sm.sm_type,
        cd.cd_gender,
        t.t_sub_shift,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt
    FROM tpcds.time_dim t
    JOIN tpcds.web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND t.t_am_pm = 'AM'
      AND sm.sm_contract = 'Ek'
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cd.cd_dep_count >= 2
)
SELECT
    cc_name,
    i_brand,
    sm_type,
    cd_gender,
    t_sub_shift,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(sr_return_amt) AS total_store_return,
    COUNT(DISTINCT ws_order_number) AS orders_cnt,
    AVG(ws_ext_discount_amt) AS avg_discount,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(ws_net_paid) DESC) AS rank_by_net_paid
FROM joined
GROUP BY
    cc_name,
    i_brand,
    sm_type,
    cd_gender,
    t_sub_shift
ORDER BY total_net_paid DESC
LIMIT 100
