WITH rs AS (
    SELECT
        sr_hdemo_sk,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt,
        AVG(sr_net_loss) AS avg_net_loss
    FROM store_returns
    WHERE sr_refunded_cash > 50
      AND sr_return_quantity >= 1
    GROUP BY sr_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    rs.total_refunded_cash,
    rs.return_cnt,
    rs.avg_net_loss
FROM catalog_sales cs
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN rs
    ON rs.sr_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_list_price > 80
  AND cs.cs_ext_ship_cost < 1500
  AND cs.cs_ship_date_sk BETWEEN 2450830 AND 2450900
  AND hd.hd_dep_count IN (4,5)
  AND hd.hd_vehicle_count >= 0
  AND hd.hd_buy_potential = '>10000'
GROUP BY
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    rs.total_refunded_cash,
    rs.return_cnt,
    rs.avg_net_loss
ORDER BY total_sales DESC
LIMIT 100
