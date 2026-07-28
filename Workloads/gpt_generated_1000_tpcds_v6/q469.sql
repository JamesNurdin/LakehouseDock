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
        cr.cr_net_loss
    FROM tpcds.catalog_returns AS cr
    WHERE cr.cr_store_credit > 50
      AND cr.cr_refunded_cash < 4000
      AND cr.cr_return_amount > 0
),
joined AS (
    SELECT
        fr.cr_returned_date_sk,
        fr.cr_returned_time_sk,
        fr.cr_item_sk,
        fr.cr_return_quantity,
        fr.cr_return_amount,
        fr.cr_refunded_cash,
        fr.cr_store_credit,
        ca_refunded.ca_state AS refunded_state,
        ca_refunded.ca_county AS refunded_county,
        ca_returning.ca_street_type AS returning_street_type
    FROM filtered_returns AS fr
    JOIN tpcds.customer_address AS ca_refunded
        ON fr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN tpcds.customer_address AS ca_returning
        ON fr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE ca_refunded.ca_state = 'CA'
      AND ca_refunded.ca_county = 'York County'
      AND ca_returning.ca_street_type = 'Lane'
)
SELECT
    refunded_state,
    refunded_county,
    returning_street_type,
    COUNT(*) AS returns_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_refunded_cash) AS avg_refunded_cash,
    MAX(cr_return_quantity) AS max_return_quantity,
    MIN(cr_return_quantity) AS min_return_quantity
FROM joined
GROUP BY
    refunded_state,
    refunded_county,
    returning_street_type
ORDER BY total_return_amount DESC
LIMIT 100
