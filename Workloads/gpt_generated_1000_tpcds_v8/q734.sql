/*
Goal: Compute yearly sales metrics by item category, combining catalog and store sales, applying several filters, removing low‑value rows, ranking categories within each year and showing a running total. The query joins all ten selected TPC‑DS tables, uses CTEs for staged aggregation, a CASE expression for price tier, UNION and EXCEPT set operations, an anti‑semi‑join (NOT IN), a window function, and final ordering with offset and fetch.
*/
WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        CASE WHEN i.i_current_price > 100 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        s.s_store_name,
        cc.cc_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
        ON cs.cs_item_sk = ss.ss_item_sk
           AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 50 AND 500
      AND cc.cc_state = 'CA'
),
agg1 AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        price_category,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM base
    GROUP BY d_year, s_store_name, i_category, price_category
),
agg2 AS (
    SELECT
        d_year   AS year,
        i_category AS category,
        AVG(total_catalog_sales) AS avg_catalog_sales
    FROM agg1
    GROUP BY d_year, i_category
    HAVING AVG(total_catalog_sales) > 10000
),
agg3 AS (
    SELECT
        d_year   AS year,
        i_category AS category,
        SUM(total_store_sales) AS total_store_sales
    FROM agg1
    GROUP BY d_year, i_category
    HAVING SUM(total_store_sales) > 20000
),
union_set AS (
    SELECT year, category, avg_catalog_sales AS metric, 'CATALOG' AS src
    FROM agg2
    UNION
    SELECT year, category, total_store_sales AS metric, 'STORE'   AS src
    FROM agg3
),
filtered AS (
    SELECT *
    FROM union_set u
    WHERE year NOT IN (SELECT d_year FROM date_dim WHERE d_year < 1990)
),
final_set AS (
    SELECT *
    FROM filtered
    EXCEPT
    SELECT year, category, metric, src
    FROM filtered
    WHERE metric < 15000
),
ranked AS (
    SELECT
        year,
        category,
        metric,
        src,
        SUM(metric) OVER (PARTITION BY year ORDER BY metric ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY metric DESC) AS rank_in_year
    FROM final_set
)
SELECT
    year,
    category,
    metric,
    src,
    running_sum,
    rank_in_year
FROM ranked
WHERE rank_in_year <= 10
ORDER BY year DESC, running_sum DESC
OFFSET 5 ROWS
FETCH NEXT 100 ROWS ONLY
