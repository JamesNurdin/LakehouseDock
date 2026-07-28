WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(*) AS txn_count,
        AVG(ss.ss_coupon_amt) AS avg_coupon,
        MAX(ss.ss_ext_discount_amt) AS max_discount
    FROM store_sales ss
    WHERE ss.ss_ext_tax > 20.00
      AND ss.ss_coupon_amt < 1000.00
      AND ss.ss_quantity > 0
    GROUP BY ss.ss_store_sk
)
SELECT
    s.s_manager,
    s.s_state,
    s.s_tax_percentage,
    COUNT(DISTINCT s.s_store_id) AS stores_count,
    SUM(sa.store_sales) AS total_sales,
    SUM(sa.store_profit) AS total_profit,
    AVG(sa.avg_coupon) AS avg_store_coupon,
    MAX(sa.max_discount) AS max_store_discount,
    SUM(sa.txn_count) AS total_transactions
FROM store s
LEFT JOIN sales_agg sa
    ON s.s_store_sk = sa.ss_store_sk
WHERE s.s_manager = 'David Thomas'
  AND s.s_tax_percentage = 0.08
  AND s.s_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_coupon_amt > 5000.00
      )
GROUP BY
    s.s_manager,
    s.s_state,
    s.s_tax_percentage
HAVING SUM(sa.store_sales) > 100000
ORDER BY total_profit DESC
LIMIT 100
