WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_hdemo_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cp.cp_description,
        cp.cp_type,
        -- extract the first word from the page description
        regexp_extract(cp.cp_description, '([A-Za-z]+)', 1) AS first_word_desc,
        -- concatenate center name and page type for reporting
        concat(cc.cc_name, ' - ', cp.cp_type) AS center_page_type
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '^Elect.*')
      AND cc.cc_name LIKE '%Center%'
      AND substring(cc.cc_city, 1, 3) = 'New'
)
SELECT
    fr.cc_call_center_id,
    fr.cc_name,
    fr.cc_city,
    fr.first_word_desc,
    fr.center_page_type,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(fr.cr_return_quantity) AS avg_return_qty
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_demo_sk = fr.cr_refunded_hdemo_sk
      AND ss.ss_net_profit > 0
)
GROUP BY
    fr.cc_call_center_id,
    fr.cc_name,
    fr.cc_city,
    fr.first_word_desc,
    fr.center_page_type
ORDER BY total_return_amount DESC
LIMIT 100
