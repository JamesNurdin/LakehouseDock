WITH agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_sales_price) AS avg_price
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sales_price > 50
      AND cs.cs_coupon_amt BETWEEN 100 AND 2000
      AND cs.cs_quantity >= 2
      AND cs.cs_net_paid_inc_tax > 100
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential IN ('>10000', '5001-10000')
    GROUP BY cs.cs_ship_mode_sk, hd.hd_buy_potential
)
SELECT
    sm.sm_ship_mode_id,
    agg.hd_buy_potential,
    agg.total_profit,
    agg.order_cnt,
    CASE WHEN agg.total_profit > 100000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM agg
JOIN tpcds.ship_mode sm
    ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE agg.order_cnt > 10
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = agg.cs_ship_mode_sk
          AND cs2.cs_coupon_amt > 500
    )
ORDER BY profit_category DESC, agg.total_profit DESC
