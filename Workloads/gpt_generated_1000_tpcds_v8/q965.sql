WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5)
),

high_vs_low_demo AS (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'High Risk'
    EXCEPT
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'Low Risk'
),

base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        t.t_shift,
        t.t_hour,
        ROW_NUMBER() OVER (ORDER BY ss.ss_sold_date_sk) AS rn
    FROM sampled_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        i.i_current_price BETWEEN 10 AND 100
        AND cd.cd_dep_college_count >= 2
        AND t.t_hour BETWEEN 6 AND 18
        AND ss.ss_quantity > 0
        AND ss.ss_ext_sales_price > 0
        AND EXISTS (
            SELECT 1
            FROM item i2
            WHERE i2.i_item_sk = ss.ss_item_sk
              AND i2.i_brand = 'Brand#12'
        )
        AND cd.cd_demo_sk IN (SELECT cd_demo_sk FROM high_vs_low_demo)
),

agg1 AS (
    SELECT
        i_brand,
        i_category,
        cd_gender,
        cd_marital_status,
        t_shift,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        AVG(ss_quantity) AS avg_qty
    FROM base
    GROUP BY ROLLUP (i_brand, i_category, cd_gender, cd_marital_status, t_shift)
),

final AS (
    SELECT
        i_brand,
        i_category,
        cd_gender,
        cd_marital_status,
        t_shift,
        total_sales,
        txn_count,
        avg_qty,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_rank
    FROM agg1
    WHERE total_sales > 1000
)
SELECT
    i_brand,
    i_category,
    cd_gender,
    cd_marital_status,
    t_shift,
    total_sales,
    txn_count,
    avg_qty,
    brand_rank
FROM final
WHERE brand_rank <= 10
ORDER BY total_sales DESC
