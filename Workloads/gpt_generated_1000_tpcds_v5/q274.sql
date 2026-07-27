WITH sales_demo AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sales_price > 20
      AND cs.cs_net_paid BETWEEN 1000 AND 8000
      AND cs.cs_coupon_amt < 500
      AND hd.hd_vehicle_count >= 1
),
sales_with_avg AS (
    SELECT
        sd.cs_quantity,
        sd.cs_sales_price,
        sd.hd_vehicle_count,
        sd.cs_coupon_amt,
        sd.hd_demo_sk,
        AVG(sd.cs_sales_price) OVER (PARTITION BY sd.hd_vehicle_count) AS avg_sales_price
    FROM sales_demo sd
)
SELECT
    s.hd_vehicle_count,
    CASE WHEN s.avg_sales_price > 30 THEN 'High' ELSE 'Medium' END AS sales_category,
    COUNT(*) AS order_cnt,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_sales_price * s.cs_quantity) AS revenue,
    SUM(s.cs_coupon_amt) AS total_coupons,
    (
        SELECT AVG(cs_sales_price)
        FROM catalog_sales
        WHERE cs_sales_price > 10
    ) AS overall_avg_price
FROM sales_with_avg s
JOIN store_returns sr
    ON s.hd_demo_sk = sr.sr_hdemo_sk
WHERE sr.sr_return_amt_inc_tax > 500
  AND sr.sr_return_tax < 10
GROUP BY s.hd_vehicle_count,
         CASE WHEN s.avg_sales_price > 30 THEN 'High' ELSE 'Medium' END
ORDER BY revenue DESC
LIMIT 100
