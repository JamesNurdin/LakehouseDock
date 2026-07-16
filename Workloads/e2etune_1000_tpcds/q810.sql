WITH sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS txn_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ss_quantity > 0
      AND ss_ext_sales_price > 0
    GROUP BY ss_store_sk
    HAVING SUM(ss_ext_sales_price) > 5000
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    s.s_tax_percentage,
    a.total_sales,
    a.total_net_profit,
    a.avg_discount,
    a.total_quantity,
    a.txn_count,
    CASE WHEN a.total_sales <> 0 THEN a.total_net_profit / a.total_sales ELSE NULL END AS net_profit_margin,
    RANK() OVER (PARTITION BY s.s_state ORDER BY a.total_net_profit DESC) AS state_profit_rank,
    PERCENT_RANK() OVER (ORDER BY a.total_net_profit DESC) AS overall_profit_percentile
FROM store s
JOIN sales_agg a
    ON s.s_store_sk = a.ss_store_sk
WHERE s.s_country = 'United States'
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND s.s_tax_percentage > 0
ORDER BY a.total_net_profit DESC
LIMIT 50
