WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_warehouse_sk IN (1, 3, 13)
      AND cr_returning_customer_sk BETWEEN 1000000 AND 6000000
      AND cr_return_quantity > 1
      AND cr_return_amount > 10
      AND cr_return_tax > 0
      AND cr_fee >= 0
),
joined AS (
    SELECT
        cc.cc_call_center_id          AS call_center_id,
        cc.cc_state                   AS cc_state,
        cc.cc_tax_percentage          AS cc_tax_percentage,
        cp.cp_department              AS cp_department,
        cp.cp_catalog_number          AS cp_catalog_number,
        CASE WHEN cc.cc_tax_percentage > 0.08 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
        fr.cr_return_amount,
        fr.cr_return_tax
    FROM filtered_returns fr
    JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_city = 'Seattle'
      AND cc.cc_country = 'United States'
      AND cp.cp_type = 'Electronic'
      AND cp.cp_start_date_sk BETWEEN 2450990 AND 2451200
      AND cp.cp_end_date_sk BETWEEN 2451050 AND 2451500
      AND cc.cc_gmt_offset BETWEEN -5 AND 0
)
SELECT
    call_center_id,
    cc_state,
    cc_tax_percentage,
    cp_department,
    cp_catalog_number,
    tax_category,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_tax)    AS total_return_tax,
    RANK() OVER (PARTITION BY cc_state ORDER BY SUM(cr_return_amount) DESC) AS state_return_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS overall_rank
FROM joined
GROUP BY
    call_center_id,
    cc_state,
    cc_tax_percentage,
    cp_department,
    cp_catalog_number,
    tax_category
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
