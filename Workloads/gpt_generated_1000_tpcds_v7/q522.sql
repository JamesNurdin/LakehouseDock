WITH return_agg AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        r.r_reason_desc,
        i.inv_quantity_on_hand,
        cc.cc_name,
        cp.cp_department,
        d.d_year
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cc.cc_sq_ft > 1000000
      AND ib.ib_lower_bound >= 50000
      AND hd.hd_buy_potential = '1001-5000'
      AND cd.cd_gender = 'F'
      AND d.d_year BETWEEN 1999 AND 2002
      AND r.r_reason_desc LIKE '%defect%'
)
SELECT
    cc_name,
    cp_department,
    COUNT(DISTINCT sr_customer_sk) AS unique_customers,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt) AS avg_return_amt,
    SUM(sr_return_quantity) AS total_return_qty
FROM return_agg
GROUP BY cc_name, cp_department
HAVING AVG(sr_return_amt) > 500
ORDER BY total_return_amt DESC
LIMIT 100
