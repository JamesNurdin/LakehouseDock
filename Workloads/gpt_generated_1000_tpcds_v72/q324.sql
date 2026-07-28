WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_fee,
        sm.sm_ship_mode_id,
        sd.s_store_name,
        sr.sr_return_amt,
        wr.wr_return_amt,
        cd.cd_gender,
        CASE
            WHEN cr.cr_return_amount > 100 THEN 'HIGH'
            WHEN cr.cr_return_amount > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_category,
        inv.inv_quantity_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN tpcds.call_center cc
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store sd
        ON sd.s_store_sk = sr.sr_store_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND cc.cc_state = 'CA'
      AND sm.sm_code = 'AIR'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    d_year,
    d_month_seq,
    return_category,
    COUNT(*) AS txn_count,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory,
    SUM(CASE WHEN return_category = 'HIGH' THEN cr_return_amount ELSE 0 END) AS high_return_sum
FROM base
GROUP BY d_year, d_month_seq, return_category
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
