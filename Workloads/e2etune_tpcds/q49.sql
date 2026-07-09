WITH agg AS (
    SELECT
        hd_bill.hd_buy_potential AS buy_potential,
        hd_bill.hd_vehicle_count AS vehicle_count,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        AVG(hd_ship.hd_income_band_sk) AS avg_shipper_income_band,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN hd_bill.hd_dep_count > 2 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS buyer_dep_gt2_ratio
    FROM
        catalog_sales cs
    JOIN
        household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN
        household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450815 AND 2450822
        AND cs.cs_ship_mode_sk = 5
        AND cs.cs_net_paid_inc_ship_tax >= 500
    GROUP BY
        hd_bill.hd_buy_potential,
        hd_bill.hd_vehicle_count
    HAVING
        SUM(cs.cs_net_profit) > 1000
)
SELECT
    buy_potential,
    vehicle_count,
    total_net_profit,
    avg_discount,
    avg_shipper_income_band,
    sales_cnt,
    buyer_dep_gt2_ratio,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 10
