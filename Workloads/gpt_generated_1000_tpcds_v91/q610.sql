WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_order_number,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_reversed_charge,
        cr_store_credit,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_reversed_charge > 20.00
        AND cr_return_ship_cost < 500.00
        AND cr_return_quantity >= 2
        AND cr_returning_addr_sk IN (5312421, 5082377, 4802697)
        AND cr_return_amount BETWEEN 100.00 AND 500.00
        AND cr_reason_sk IN (
            SELECT r_reason_sk
            FROM reason
            WHERE r_reason_desc LIKE '%price%'
        )
)
SELECT
    COALESCE(r.r_reason_desc, 'Unknown Reason') AS reason_desc,
    COUNT(fr.cr_order_number) AS num_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount,
    SUM(fr.cr_return_tax) AS total_return_tax,
    SUM(fr.cr_return_ship_cost) AS total_ship_cost,
    SUM(fr.cr_reversed_charge) AS total_reversed_charge
FROM filtered_returns fr
LEFT JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
GROUP BY COALESCE(r.r_reason_desc, 'Unknown Reason')
HAVING COUNT(fr.cr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100
