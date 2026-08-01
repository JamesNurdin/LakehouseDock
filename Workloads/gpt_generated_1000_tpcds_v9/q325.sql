WITH RECURSIVE profit_bins (bin_start) AS (
    SELECT 0
    UNION ALL
    SELECT bin_start + 10000 FROM profit_bins WHERE bin_start + 10000 <= 50000
)
SELECT
    cc.cc_name,
    wh.w_city,
    pb.bin_start,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid_inc_ship) AS total_rev,
    AVG(cs.cs_coupon_amt) AS avg_coupon,
    MIN(cs.cs_net_profit) AS min_profit,
    MAX(cs.cs_net_profit) AS max_profit
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN profit_bins pb ON cs.cs_net_profit >= pb.bin_start
                     AND cs.cs_net_profit < pb.bin_start + 10000
WHERE
    cc.cc_state = 'CA'
    AND cc.cc_hours = '8AM-4PM'
    AND cc.cc_company_name = 'cally'
    AND wh.w_county = 'Fairfield County'
    AND wh.w_country = 'United States'
    AND cs.cs_net_paid_inc_ship > 2000
    AND cs.cs_coupon_amt > (
        SELECT AVG(cs2.cs_coupon_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_coupon_amt IS NOT NULL
    )
GROUP BY ROLLUP (cc.cc_name, wh.w_city, pb.bin_start)
HAVING SUM(cs.cs_net_paid_inc_ship) > 5000
ORDER BY total_rev DESC
