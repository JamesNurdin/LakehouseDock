WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        d.d_year,
        c.c_preferred_cust_flag,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'high' ELSE 'low' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    jd.cc_call_center_id,
    jd.w_warehouse_id,
    jd.return_category,
    SUM(jd.cr_return_amount) AS total_return_amount,
    AVG(jd.ws_net_profit) AS avg_ws_net_profit,
    (SELECT COUNT(*)
     FROM catalog_returns cr_sub
     WHERE cr_sub.cr_call_center_sk = jd.cc_call_center_sk) AS total_returns_for_center
FROM joined_data jd
GROUP BY
    jd.cc_call_center_id,
    jd.w_warehouse_id,
    jd.return_category,
    jd.cc_call_center_sk
HAVING SUM(jd.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
