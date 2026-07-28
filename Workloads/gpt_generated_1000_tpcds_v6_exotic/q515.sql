WITH
    warehouse_filtered AS (
        SELECT DISTINCT
            w.w_warehouse_sk,
            w.w_suite_number,
            w.w_city,
            w.w_state
        FROM warehouse w
        WHERE w.w_suite_number LIKE 'Suite %'
          AND regexp_like(w.w_city, '^[A-Z][a-z]+')
    ),
    sales_agg AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_state,
            wf.w_warehouse_sk,
            wf.w_suite_number,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt,
            ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse_filtered wf ON cs.cs_warehouse_sk = wf.w_warehouse_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND regexp_like(cc.cc_name, 'Center')
        GROUP BY
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_state,
            wf.w_warehouse_sk,
            wf.w_suite_number
        HAVING SUM(cs.cs_net_profit) > 10000
    )
SELECT
    sa.cc_call_center_sk,
    sa.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    substring(sa.cc_state FROM 1 FOR 2) AS state_abbr,
    sa.w_warehouse_sk,
    regexp_extract(sa.w_suite_number, 'Suite ([A-Z0-9]+)', 1) AS suite_code,
    sa.total_net_profit,
    sa.sales_cnt,
    sa.profit_rank
FROM sales_agg sa
JOIN call_center cc ON sa.cc_call_center_sk = cc.cc_call_center_sk
ORDER BY sa.total_net_profit DESC, sa.cc_name
LIMIT 100
