WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_category,
        i_class,
        i_brand,
        i_formulation,
        regexp_extract(i_formulation, '([0-9]+)', 1) AS formulation_number,
        regexp_extract(i_formulation, '[a-zA-Z]+$', 1) AS formulation_suffix
    FROM
        item
    WHERE
        i_formulation LIKE '%pink%'
        AND regexp_like(i_formulation, '[0-9]+.*pink')
),
sales_by_item AS (
    SELECT
        fi.i_category,
        fi.i_class,
        fi.i_brand,
        fi.i_formulation,
        fi.formulation_number,
        fi.formulation_suffix,
        ss.ss_ext_sales_price,
        ss.ss_customer_sk
    FROM
        store_sales ss
        JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        ib.ib_lower_bound >= 50000
),
distinct_sales AS (
    SELECT DISTINCT
        i_category,
        i_class,
        i_brand,
        i_formulation,
        formulation_number,
        formulation_suffix,
        ss_ext_sales_price,
        ss_customer_sk
    FROM
        sales_by_item
)
SELECT
    i_category,
    i_class,
    i_brand,
    concat(i_brand, ' - ', i_category) AS brand_category,
    sum(ss_ext_sales_price) AS total_sales,
    count(DISTINCT ss_customer_sk) AS distinct_customers,
    formulation_number,
    formulation_suffix
FROM
    distinct_sales
GROUP BY
    i_category,
    i_class,
    i_brand,
    formulation_number,
    formulation_suffix
ORDER BY
    total_sales DESC
LIMIT 100
