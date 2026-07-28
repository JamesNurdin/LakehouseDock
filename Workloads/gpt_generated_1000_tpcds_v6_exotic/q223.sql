WITH sales_by_cc AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
        SUBSTRING(cc.cc_name, 1, 3) AS name_prefix,
        REGEXP_EXTRACT(cc.cc_name, '(Center)', 1) AS extracted_word,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        REGEXP_LIKE(cc.cc_name, '^.*Center.*$')
        AND sm.sm_type LIKE 'AIR%'
        AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year
)
SELECT
    cc_name,
    location,
    name_prefix,
    extracted_word,
    d_year,
    total_profit,
    txn_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_by_cc
ORDER BY d_year, profit_rank
LIMIT 100
