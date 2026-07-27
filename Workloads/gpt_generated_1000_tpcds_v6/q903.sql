WITH filtered_sales AS (
    SELECT
        cs.cs_bill_hdemo_sk,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_order_number,
        hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '^M.*')
      AND cs.cs_coupon_amt > 100
)
SELECT
    CONCAT('Potential:', hd_buy_potential) AS potential_label,
    regexp_extract(hd_buy_potential, '(\\d+)', 1) AS potential_number,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_coupon_amt) AS avg_coupon_amt
FROM filtered_sales
GROUP BY
    CONCAT('Potential:', hd_buy_potential),
    regexp_extract(hd_buy_potential, '(\\d+)', 1)
ORDER BY total_net_profit DESC
LIMIT 10
