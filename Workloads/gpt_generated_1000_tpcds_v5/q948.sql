WITH sales_by_cc_date AS (
    SELECT
        cc.cc_name,
        cc.cc_market_manager,
        cc.cc_division,
        d.d_year,
        d.d_quarter_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN call_center cc
        ON cc.cc_closed_date_sk = ss.ss_sold_date_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq BETWEEN 10 AND 20
      AND cc.cc_market_manager = 'James Mcdonald'
      AND ss.ss_sales_price > 10.00
    GROUP BY cc.cc_name, cc.cc_market_manager, cc.cc_division, d.d_year, d.d_quarter_seq
)
SELECT
    agg.cc_name,
    agg.d_year,
    AVG(agg.total_sales) AS avg_sales_per_quarter,
    SUM(agg.total_profit) AS sum_profit,
    (SELECT COUNT(*) FROM call_center WHERE cc_division = agg.cc_division) AS division_cc_cnt
FROM sales_by_cc_date agg
WHERE EXISTS (
    SELECT 1 FROM call_center cc2
    WHERE cc2.cc_division = agg.cc_division
      AND cc2.cc_market_manager <> agg.cc_market_manager
)
GROUP BY agg.cc_name, agg.d_year, agg.cc_division, agg.cc_market_manager
HAVING AVG(agg.total_sales) > 50000
ORDER BY sum_profit DESC
LIMIT 100
