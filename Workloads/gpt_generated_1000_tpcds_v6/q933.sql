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
        cp.cp_department,
        cp.cp_description,
        cp.cp_end_date_sk,
        cp.cp_start_date_sk,
        td.t_time,
        td.t_second,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_amount_category
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_end_date_sk BETWEEN 2450990 AND 2451100
      AND cp.cp_description LIKE '%store%'
      AND cr.cr_store_credit > 50
      AND cr.cr_refunded_cash BETWEEN 500 AND 2000
      AND td.t_time IN (9, 11, 13)
      AND td.t_second <= 8
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_number = cp.cp_catalog_number
            AND cp2.cp_description LIKE '%new%'
      )
)
SELECT
    cp_department,
    return_amount_category,
    COUNT(*) AS returns_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_tax,
    MAX(cr_return_quantity) AS max_quantity,
    MIN(cr_return_amt_inc_tax) AS min_amount_inc_tax
FROM filtered_returns
GROUP BY cp_department, return_amount_category
ORDER BY total_return_amount DESC
LIMIT 100
