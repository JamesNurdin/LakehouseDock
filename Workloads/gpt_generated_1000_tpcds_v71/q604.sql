/* goal: Calculate profit category and detailed sales metrics per ship mode, applying multiple realistic filters, and show subtotals using GROUPING SETS */
WITH filtered_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_ext_list_price,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_list_price BETWEEN 1000 AND 8000
      AND cs.cs_coupon_amt > 50
      AND cs.cs_quantity >= 2
      AND cs.cs_promo_sk IN (1057, 1023, 73)
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_contract,
    CASE WHEN SUM(f.cs_net_profit) > 1000000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    COUNT(*) AS order_cnt,
    SUM(f.cs_ext_sales_price) AS total_sales,
    AVG(f.cs_coupon_amt) AS avg_coupon,
    MIN(f.cs_ext_discount_amt) AS min_discount,
    MAX(f.cs_ext_discount_amt) AS max_discount
FROM filtered_sales f
JOIN ship_mode sm
    ON f.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_ship_mode_id = 'AAAAAAAADAAAAAAA'
  AND sm.sm_contract LIKE 'I3uCel%'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = f.cs_ship_mode_sk
          AND cs2.cs_ext_list_price > 5000
        LIMIT 1
    )
GROUP BY GROUPING SETS (
        (sm.sm_ship_mode_id, sm.sm_contract),
        ()
    )
HAVING SUM(f.cs_net_profit) IS NOT NULL
   AND COUNT(*) > 10
ORDER BY profit_category DESC, total_sales DESC
LIMIT 100
