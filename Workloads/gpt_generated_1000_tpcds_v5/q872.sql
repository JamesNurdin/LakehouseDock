WITH joined AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_returned_date_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        i.i_item_id,
        i.i_product_name,
        i.i_units,
        i.i_manufact_id,
        p.p_promo_name,
        r.r_reason_desc,
        ca.ca_city,
        hd.hd_income_band_sk,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_ship_cost > 100
      AND cc.cc_state = 'CA'
      AND i.i_units = 'Each      '
      AND r.r_reason_id LIKE 'AAAA%'
      AND i.i_manufact_id = 26
)
SELECT
    cc_call_center_id,
    cc_state,
    i_item_id,
    i_product_name,
    amount_category,
    cr_return_amount,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY cr_return_amount DESC) AS return_rank,
    SUM(cr_return_amount) OVER (PARTITION BY cc_call_center_id) AS total_return_amount_by_center
FROM joined
ORDER BY return_rank ASC, cr_return_amount DESC
LIMIT 100
