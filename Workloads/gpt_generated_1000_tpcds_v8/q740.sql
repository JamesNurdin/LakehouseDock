WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_sold_time_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales
    WHERE cs_ext_sales_price > 500
      AND cs_quantity BETWEEN 1 AND 10
      AND cs_ext_discount_amt < 200
      AND cs_net_paid_inc_ship > 0
    GROUP BY cs_call_center_sk, cs_sold_time_sk, cs_bill_hdemo_sk
),
intersect_cc AS (
    SELECT cc_call_center_sk FROM call_center WHERE cc_zip LIKE '74%'
    INTERSECT
    SELECT cs_call_center_sk FROM catalog_sales WHERE cs_ext_sales_price > 2000
)
SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    td.t_hour,
    hd.hd_buy_potential,
    SUM(sa.total_sales) AS sum_sales,
    COUNT(DISTINCT sa.cs_call_center_sk) AS distinct_call_centers,
    COUNT(DISTINCT hd.hd_demo_sk) AS distinct_demo_keys,
    CASE
        WHEN SUM(sa.total_profit) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT AVG(total_sales) FROM sales_agg) AS avg_total_sales_overall
FROM sales_agg sa
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td ON sa.cs_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND td.t_am_pm = 'PM'
  AND cc.cc_zip LIKE '74%'
  AND hd.hd_vehicle_count > 1
  AND td.t_shift = 'first               '
  AND cc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_cc)
  AND cc.cc_call_center_id NOT IN (SELECT cc_call_center_id FROM call_center WHERE cc_gmt_offset < 0)
GROUP BY cc.cc_call_center_id, cc.cc_city, td.t_hour, hd.hd_buy_potential
HAVING SUM(sa.total_sales) > 2000
   AND COUNT(DISTINCT hd.hd_demo_sk) >= 2
ORDER BY sum_sales DESC, profit_category
OFFSET 20 LIMIT 100
