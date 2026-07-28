WITH base AS (
    SELECT DISTINCT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        cs.cs_ext_sales_price,
        i.i_category,
        i.i_wholesale_cost,
        hd.hd_income_band_sk,
        s.s_state,
        s.s_zip
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_wholesale_cost > 5.00
      AND hd.hd_income_band_sk = 11
      AND s.s_zip = '40411'
),
agg AS (
    SELECT
        s_state,
        i_category,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(cs_ext_sales_price) AS catalog_sales_total,
        AVG(i_wholesale_cost) AS avg_wholesale_cost
    FROM base
    GROUP BY s_state, i_category
    HAVING SUM(ss_ext_sales_price) > 1000
)
SELECT
    s_state,
    i_category,
    distinct_tickets,
    store_sales_total,
    catalog_sales_total,
    avg_wholesale_cost,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY store_sales_total DESC) AS rn
FROM agg
ORDER BY store_sales_total DESC
LIMIT 100
