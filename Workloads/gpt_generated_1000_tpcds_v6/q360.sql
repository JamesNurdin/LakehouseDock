WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
)
SELECT
    st.s_store_name,
    st.s_city,
    rs.r_reason_desc,
    sr.cnt_returns,
    sr.total_return_amt,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(cr.cr_order_number) AS cnt_catalog_returns,
    (
        SELECT MAX(cp2.cp_catalog_page_id)
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) AS latest_page_id
FROM store_ret_agg sr
JOIN store st ON sr.sr_store_sk = st.s_store_sk
JOIN reason rs ON sr.sr_reason_sk = rs.r_reason_sk
JOIN catalog_returns cr ON cr.cr_reason_sk = rs.r_reason_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
WHERE rs.r_reason_desc IN (
        SELECT DISTINCT r_reason_desc
        FROM reason
        WHERE r_reason_desc LIKE 'Did not%'
    )
  AND sm.sm_type = 'EXPRESS'
  AND cp.cp_end_date_sk = 2451178
  AND st.s_state = 'CA'
GROUP BY
    st.s_store_name,
    st.s_city,
    rs.r_reason_desc,
    sr.cnt_returns,
    sr.total_return_amt,
    cr.cr_catalog_page_sk
ORDER BY sr.total_return_amt DESC
LIMIT 100
