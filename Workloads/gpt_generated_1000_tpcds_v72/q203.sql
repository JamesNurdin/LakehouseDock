WITH store_sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_market_manager,
        s.s_tax_percentage,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451220  -- example surrogate key range for a quarter
      AND s.s_market_manager IN ('Edward Stone', 'Lawrence Nettles')
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_market_manager,
        s.s_tax_percentage
)
SELECT
    ssa.s_store_id,
    ssa.s_market_manager,
    ssa.profit_category,
    ssa.total_sales,
    ssa.total_net_profit,
    'HighTax' AS tax_group
FROM store_sales_agg ssa
WHERE ssa.s_tax_percentage >= 0.05
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ssa.s_store_sk
          AND ss2.ss_coupon_amt > 200
    )
UNION ALL
SELECT
    ssa.s_store_id,
    ssa.s_market_manager,
    ssa.profit_category,
    ssa.total_sales,
    ssa.total_net_profit,
    'LowTax' AS tax_group
FROM store_sales_agg ssa
WHERE ssa.s_tax_percentage < 0.05
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ssa.s_store_sk
          AND ss2.ss_coupon_amt > 200
    )
ORDER BY total_net_profit DESC
LIMIT 100
