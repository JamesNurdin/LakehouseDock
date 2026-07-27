WITH catalog_sales_agg AS (
    SELECT
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price) AS cat_sales_total,
        SUM(cs.cs_net_paid) AS cat_net_paid_total
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 14
      AND cs.cs_quantity > 2
    GROUP BY cs.cs_order_number
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    COUNT(DISTINCT ss.ss_ticket_number)                     AS store_txn_cnt,
    SUM(ss.ss_net_paid)                                      AS store_net_paid,
    SUM(sr.sr_return_amt)                                    AS store_return_amt,
    SUM(sr.sr_fee)                                           AS store_return_fee_total,
    SUM(ws.ws_net_paid)                                      AS web_net_paid,
    SUM(wr.wr_return_amt)                                    AS web_return_amt,
    SUM(cr.cr_return_amount)                                 AS catalog_return_amt,
    SUM(cs_agg.cat_sales_total)                              AS catalog_sales_total,
    AVG(cs.cs_ext_discount_amt)                              AS avg_catalog_discount,
    MIN(sr.sr_fee)                                           AS min_store_fee,
    MAX(sr.sr_fee)                                           AS max_store_fee
FROM time_dim td
JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_sales_agg cs_agg ON cs_agg.cs_order_number = cs.cs_order_number
WHERE td.t_hour = 14
  AND c.c_birth_year BETWEEN 1970 AND 1980
  AND ca.ca_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND cp.cp_department = 'Electronics'
  AND ss.ss_quantity > 5
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND r2.r_reason_desc = 'Damaged'
    )
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type
ORDER BY store_net_paid DESC
LIMIT 100
