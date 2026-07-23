WITH filtered_cr AS (
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
        cp.cp_type,
        cp.cp_catalog_number,
        d.d_year,
        d.d_month_seq,
        d.d_moy
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number IN (6, 12, 16)
      AND d.d_year = 2001
      AND d.d_moy = 7
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10.0
      AND cr.cr_fee < 5.0
)
SELECT
    d.d_year,
    d.d_month_seq,
    cr.cp_department,
    cr.cp_type,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_order_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    COUNT(sr.sr_ticket_number) AS store_return_cnt
FROM filtered_cr cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_returned_date_sk = d.d_date_sk
      AND sr2.sr_return_amt > 20.0
)
GROUP BY d.d_year, d.d_month_seq, cr.cp_department, cr.cp_type
ORDER BY d.d_year DESC, total_return_amount DESC
LIMIT 100
