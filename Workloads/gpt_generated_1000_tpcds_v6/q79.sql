WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND s.s_gmt_offset BETWEEN -5.00 AND 5.00
      AND ss.ss_wholesale_cost > 20.00
      AND ss.ss_sales_price > 30.00
    GROUP BY ss.ss_store_sk
    HAVING COUNT(*) >= 10
)
SELECT
    s.s_store_name,
    s.s_division_id,
    agg.total_sales,
    agg.total_profit,
    agg.sales_cnt,
    (agg.total_profit / NULLIF(agg.sales_cnt, 0)) AS avg_profit_per_sale
FROM sales_agg agg
JOIN store s
    ON agg.store_sk = s.s_store_sk
WHERE EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_profit > 1000
        LIMIT 1
    )
  AND s.s_store_id IN (
        SELECT DISTINCT s2.s_store_id
        FROM store s2
        JOIN store_sales ss3 ON ss3.ss_store_sk = s2.s_store_sk
        WHERE ss3.ss_net_profit > 0
    )
ORDER BY agg.total_sales DESC
LIMIT 100
