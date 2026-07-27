WITH catalog_sub AS (
    SELECT 
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_return_amount AS return_amount,
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        r.r_reason_desc AS reason_desc,
        hd.hd_income_band_sk AS income_band_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND sm.sm_type = 'EXPRESS'
      AND cr.cr_return_amount > 100
),
store_sub AS (
    SELECT 
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_return_amt AS return_amount,
        CAST(NULL AS varchar) AS department,
        CAST(NULL AS varchar) AS ship_type,
        r.r_reason_desc AS reason_desc,
        hd.hd_income_band_sk AS income_band_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 100
      AND sr.sr_store_credit < 20
)
SELECT returned_date_sk,
       return_amount,
       department,
       ship_type,
       reason_desc,
       income_band_sk
FROM catalog_sub
UNION ALL
SELECT returned_date_sk,
       return_amount,
       department,
       ship_type,
       reason_desc,
       income_band_sk
FROM store_sub
ORDER BY return_amount DESC
LIMIT 100
