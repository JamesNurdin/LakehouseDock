WITH sales_with_demo AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM store_sales ss
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
        ss.ss_sales_price > 20
        AND ss.ss_coupon_amt >= 0
        AND (hd.hd_vehicle_count >= 1 OR hd.hd_vehicle_count IS NULL)
        AND (hd.hd_buy_potential IN ('5001-10000', '>10000') OR hd.hd_buy_potential IS NULL)
        AND NOT EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = ss.ss_hdemo_sk
              AND hd2.hd_dep_count = 0
        )
)
SELECT
    ssd.ss_store_sk,
    ssd.ss_hdemo_sk,
    ssd.hd_vehicle_count,
    ssd.hd_buy_potential,
    ssd.ss_sales_price,
    ssd.ss_ext_sales_price,
    ssd.ss_net_profit,
    ssd.ss_coupon_amt,
    CASE WHEN ssd.ss_coupon_amt > 0 THEN 'HasCoupon' ELSE 'NoCoupon' END AS coupon_flag,
    (SELECT SUM(ss2.ss_ext_sales_price)
     FROM store_sales ss2
     WHERE ss2.ss_store_sk = ssd.ss_store_sk) AS store_total_sales,
    RANK() OVER (PARTITION BY ssd.ss_store_sk ORDER BY ssd.ss_net_profit DESC) AS profit_rank
FROM sales_with_demo ssd
WHERE ssd.hd_vehicle_count IS NOT NULL
ORDER BY profit_rank ASC, ssd.ss_net_paid DESC
LIMIT 100
