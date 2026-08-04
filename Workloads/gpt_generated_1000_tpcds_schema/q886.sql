WITH sampled_returns AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    filtered AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            i.i_item_sk,
            i.i_item_id,
            i.i_size,
            i.i_brand,
            cp.cp_department,
            cp.cp_catalog_page_number,
            ca.ca_county,
            hd.hd_income_band_sk,
            hd.hd_dep_count,
            ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS rn_dept
        FROM sampled_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE i.i_size IN ('large', 'extra large')
          AND ca.ca_county = 'Barry County'
          AND hd.hd_income_band_sk >= 10
    ),
    agg_cube AS (
        SELECT
            cp.cp_department,
            i.i_brand,
            hd.hd_dep_count,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS cnt_returns
        FROM sampled_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        GROUP BY CUBE (cp.cp_department, i.i_brand, hd.hd_dep_count)
    ),
    intersect_keys AS (
        SELECT DISTINCT cr.cr_item_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 2000
        INTERSECT
        SELECT DISTINCT cr.cr_item_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity >= 2
    )
SELECT
    f.cr_returned_date_sk,
    f.i_item_id,
    f.i_size,
    f.i_brand,
    f.cp_department,
    f.cp_catalog_page_number,
    f.ca_county,
    f.hd_income_band_sk,
    f.hd_dep_count,
    f.cr_return_amount,
    f.rn_dept,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = f.i_item_sk
    ) AS avg_return_amount_for_item,
    ac.total_return_amount,
    ac.cnt_returns
FROM filtered f
LEFT JOIN agg_cube ac
    ON ac.cp_department = f.cp_department
   AND ac.i_brand = f.i_brand
   AND ac.hd_dep_count = f.hd_dep_count
WHERE f.rn_dept <= 5
  AND f.i_item_id IN (
        SELECT i_item_id
        FROM item
        WHERE i_current_price > 50
    )
  AND EXISTS (
        SELECT 1
        FROM intersect_keys ik
        WHERE ik.cr_item_sk = f.i_item_sk
    )
ORDER BY f.cp_department, f.cr_return_amount DESC
LIMIT 100
