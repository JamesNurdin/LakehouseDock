/*
Goal: Analyze net profit and sales performance by store and item category, enriched with household demographic, income band, and store timezone information. The query uses a sampled CTE, multiple aliased joins (including left outer joins), a DISTINCT clause, and expands a derived array with UNNEST.
*/
WITH sample_sales AS (
    SELECT DISTINCT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ARRAY[ss.ss_quantity, CAST(ss.ss_net_profit AS DOUBLE)] AS qty_profit_arr
    FROM tpcds.store_sales ss
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    i.i_category,
    i.i_brand,
    ib1.ib_lower_bound AS income_lower,
    ib2.ib_upper_bound AS income_upper,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(hd1.hd_vehicle_count) AS avg_vehicle_count,
    AVG(hd2.hd_dep_count) AS avg_dep_count,
    AVG(i2.i_current_price) AS avg_price_alternate,
    MAX(COALESCE(s2.s_gmt_offset, 0)) AS s2_gmt_offset,
    SUM(t.qty_profit) AS sum_qty_or_profit
FROM sample_sales ss
JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.item i2
    ON ss.ss_item_sk = i2.i_item_sk
JOIN tpcds.household_demographics hd1
    ON ss.ss_hdemo_sk = hd1.hd_demo_sk
LEFT JOIN tpcds.household_demographics hd2
    ON ss.ss_hdemo_sk = hd2.hd_demo_sk
JOIN tpcds.income_band ib1
    ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
JOIN tpcds.income_band ib2
    ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN tpcds.store s2
    ON ss.ss_store_sk = s2.s_store_sk
CROSS JOIN UNNEST(ss.qty_profit_arr) AS t(qty_profit)
GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_brand,
    ib1.ib_lower_bound,
    ib2.ib_upper_bound
ORDER BY total_net_profit DESC
LIMIT 100
