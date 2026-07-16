WITH dept_ship_income AS (
    SELECT
        cp.cp_department,
        sm.sm_type,
        ib.ib_income_band_sk,
        COUNT(DISTINCT i.i_item_sk) AS num_items,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost
    FROM
        catalog_page cp
        JOIN ship_mode sm
            ON cp.cp_catalog_page_sk = sm.sm_ship_mode_sk
        JOIN item i
            ON cp.cp_catalog_page_number = i.i_category_id
        JOIN income_band ib
            ON i.i_current_price >= ib.ib_lower_bound
            AND i.i_current_price < ib.ib_upper_bound
    WHERE
        cp.cp_start_date_sk = 2450906
        AND cp.cp_end_date_sk > 2450995
        AND cp.cp_catalog_number IN (1, 2, 3)
        AND i.i_brand = 'Brand#12'
        AND sm.sm_carrier = 'CarrierA'
    GROUP BY
        cp.cp_department,
        sm.sm_type,
        ib.ib_income_band_sk
    HAVING
        COUNT(DISTINCT i.i_item_sk) > 10
)
SELECT
    cp_department,
    sm_type,
    ib_income_band_sk,
    num_items,
    avg_price,
    total_wholesale_cost,
    RANK() OVER (PARTITION BY cp_department ORDER BY avg_price DESC) AS price_rank
FROM dept_ship_income
ORDER BY cp_department, price_rank
