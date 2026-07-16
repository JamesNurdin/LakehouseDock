WITH order_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_net_paid) AS order_net_paid,
        SUM(cs.cs_ext_discount_amt) AS order_discount,
        MAX(cs.cs_coupon_amt) AS max_coupon
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 0
      AND cs.cs_sold_time_sk IN (67495, 71945, 19606, 46697)
    GROUP BY cs.cs_order_number, cs.cs_sold_time_sk, cs.cs_bill_hdemo_sk, cs.cs_ship_hdemo_sk
)
SELECT
    t.t_hour,
    hd_bill.hd_buy_potential AS bill_buy_potential,
    hd_ship.hd_buy_potential AS ship_buy_potential,
    COUNT(DISTINCT os.cs_order_number) AS orders,
    SUM(os.order_net_paid) AS total_net_paid,
    SUM(os.order_discount) AS total_discount,
    AVG(os.max_coupon) AS avg_max_coupon,
    SUM(os.order_net_paid) / COUNT(DISTINCT os.cs_order_number) AS avg_net_per_order,
    ROW_NUMBER() OVER (PARTITION BY t.t_hour ORDER BY SUM(os.order_net_paid) DESC) AS rank_by_hour
FROM order_sales os
JOIN time_dim t ON os.cs_sold_time_sk = t.t_time_sk
JOIN household_demographics hd_bill ON os.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON os.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE hd_bill.hd_income_band_sk BETWEEN 3 AND 7
  AND hd_ship.hd_vehicle_count >= 2
GROUP BY t.t_hour, hd_bill.hd_buy_potential, hd_ship.hd_buy_potential
HAVING SUM(os.order_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
