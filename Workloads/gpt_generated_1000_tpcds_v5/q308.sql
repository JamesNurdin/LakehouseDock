WITH sales_agg AS (
    SELECT ss_store_sk,
           SUM(ss_net_profit) AS total_net_profit,
           SUM(ss_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM store_sales
    GROUP BY ss_store_sk
),
returns_agg AS (
    SELECT sr_store_sk,
           SUM(sr_return_amt) AS total_return_amt,
           SUM(sr_refunded_cash) AS total_refunded_cash,
           COUNT(*) AS returns_cnt
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state) AS location,
    s.s_store_name,
    REGEXP_EXTRACT(s.s_store_name, '(\\d+)', 1) AS store_number_extracted,
    CASE
        WHEN sales.total_net_profit > 100000 THEN 'High Profit'
        WHEN sales.total_net_profit > 50000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    sales.total_net_profit,
    returns.total_return_amt,
    (sales.total_net_profit - returns.total_return_amt) AS net_profit_after_returns,
    CASE
        WHEN REGEXP_LIKE(s.s_store_name, '^A.*') THEN 'StartsWithA'
        ELSE 'Other'
    END AS name_pattern,
    CASE
        WHEN s.s_city LIKE 'San %' THEN 'California City'
        ELSE 'Other City'
    END AS city_group
FROM store s
LEFT JOIN sales_agg sales ON sales.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg returns ON returns.sr_store_sk = s.s_store_sk
WHERE s.s_market_id IN (2, 3, 5)
  AND REGEXP_LIKE(s.s_manager, '^[A-Z][a-z]+ [A-Z][a-z]+$')
ORDER BY net_profit_after_returns DESC
LIMIT 100
