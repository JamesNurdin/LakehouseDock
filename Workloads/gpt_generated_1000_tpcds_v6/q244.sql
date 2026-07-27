WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cc.cc_name,
        w.w_city,
        td.t_hour,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_minute BETWEEN 5 AND 15
      AND w.w_gmt_offset = -5.00
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND cr.cr_return_amount > 100
)
SELECT
    cc_name,
    w_city,
    t_hour,
    r_reason_desc,
    COUNT(*) AS return_count,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_quantity,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM filtered_returns
GROUP BY
    cc_name,
    w_city,
    t_hour,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
