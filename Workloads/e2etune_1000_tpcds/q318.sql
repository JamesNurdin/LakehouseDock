WITH agg AS (
    SELECT
        sm.sm_type AS sm_type,
        bill_hd.hd_buy_potential AS bill_buy_potential,
        ship_hd.hd_vehicle_count AS ship_vehicle_count,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit,
        avg(cs.cs_ext_discount_amt) AS avg_discount,
        count(distinct cs.cs_order_number) AS distinct_orders,
        sum(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN household_demographics bill_hd
        ON cs.cs_bill_hdemo_sk = bill_hd.hd_demo_sk
    JOIN household_demographics ship_hd
        ON cs.cs_ship_hdemo_sk = ship_hd.hd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_tax > 20
      AND cs.cs_coupon_amt = 0.00
    GROUP BY sm.sm_type, bill_hd.hd_buy_potential, ship_hd.hd_vehicle_count
    HAVING sum(cs.cs_ext_sales_price) > 10000
)
SELECT
    sm_type,
    bill_buy_potential,
    ship_vehicle_count,
    total_sales,
    total_profit,
    avg_discount,
    distinct_orders,
    total_quantity,
    (total_profit / total_sales) AS profit_margin,
    rank() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY profit_margin DESC
LIMIT 50
