/*
Goal: Identify high‑performing call centers (names starting with "A") that serve customers with at least two employed dependents, ship from warehouses whose suite numbers match the pattern "Suite %", and have at least one related web return with a fee greater than 20. The query extracts the numeric part of the warehouse suite, builds a concatenated center‑city label, aggregates net profit and order counts, and limits the result to the top 100 rows.
*/
WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk
    FROM catalog_sales cs
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.cs_order_number
          AND wr.wr_fee > 20
    )
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_name || ' - ' || cc.cc_city AS center_city,
    w.w_warehouse_id,
    regexp_extract(w.w_suite_number, '(\\d+)', 1) AS suite_number_digits,
    SUM(cs_filtered.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs_filtered.cs_order_number) AS distinct_orders
FROM cs_filtered
JOIN call_center cc
  ON cs_filtered.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs_filtered.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
  ON cs_filtered.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    regexp_like(cc.cc_name, '^A.*')
    AND cd.cd_dep_employed_count >= 2
    AND w.w_suite_number LIKE 'Suite %'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_name || ' - ' || cc.cc_city,
    w.w_warehouse_id,
    regexp_extract(w.w_suite_number, '(\\d+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
