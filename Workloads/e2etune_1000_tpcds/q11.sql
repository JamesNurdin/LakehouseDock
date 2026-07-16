WITH dem_item AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        i.i_wholesale_cost,
        i.i_brand_id
    FROM customer_demographics cd
    JOIN item i
        ON cd.cd_demo_sk = i.i_item_sk
    WHERE cd.cd_gender = 'F'
      AND i.i_current_price BETWEEN 10 AND 200
),

dem_item_income AS (
    SELECT
        di.*,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM dem_item di
    JOIN income_band ib
        ON di.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
),

full_data AS (
    SELECT
        dii.*,
        w.w_warehouse_sk,
        w.w_state,
        w.w_country,
        w.w_warehouse_sq_ft
    FROM dem_item_income dii
    JOIN warehouse w
        ON dii.i_brand_id = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
),

agg AS (
    SELECT
        fd.w_state,
        fd.i_category,
        COUNT(*) AS num_customers,
        AVG(fd.i_current_price) AS avg_item_price,
        SUM(fd.i_wholesale_cost) AS total_wholesale_cost,
        AVG(fd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN fd.cd_dep_employed_count > 0 THEN 1 ELSE 0 END) AS employed_deps
    FROM full_data fd
    GROUP BY fd.w_state, fd.i_category
    HAVING COUNT(*) >= 5
)
SELECT
    a.w_state,
    a.i_category,
    a.num_customers,
    a.avg_item_price,
    a.total_wholesale_cost,
    a.avg_purchase_estimate,
    a.employed_deps,
    RANK() OVER (PARTITION BY a.w_state ORDER BY a.avg_item_price DESC) AS price_rank_in_state
FROM agg a
ORDER BY a.w_state, a.avg_item_price DESC
LIMIT 50
