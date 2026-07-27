WITH
sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_sold_time_sk AS time_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_wholesale_cost BETWEEN 5.00 AND 50.00
      AND cs.cs_list_price > 10.00
      AND cs.cs_ext_sales_price > 100.00
      AND cs.cs_ext_discount_amt < 20.00
      AND cs.cs_ext_tax >= 5.00
    GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_time_sk
),
returns_agg AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        sr.sr_return_time_sk AS time_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 50.00
      AND sr.sr_return_tax >= 5.00
      AND sr.sr_fee < 20.00
      AND sr.sr_return_ship_cost BETWEEN 0 AND 30.00
      AND sr.sr_reversed_charge = 0
    GROUP BY sr.sr_customer_sk, sr.sr_return_time_sk
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    t.t_hour,
    s.total_sales,
    s.avg_discount,
    s.sales_cnt,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    CASE
        WHEN COALESCE(r.total_return_amt, 0) > 5000 THEN 'HIGH'
        WHEN COALESCE(r.total_return_amt, 0) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_category,
    COALESCE(r.total_net_loss, 0) AS total_net_loss
FROM sales_agg s
JOIN customer c
    ON s.cust_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg r
    ON s.cust_sk = r.cust_sk
   AND s.time_sk = r.time_sk
JOIN time_dim t
    ON s.time_sk = t.t_time_sk
WHERE cd.cd_purchase_estimate >= 5000
  AND cd.cd_dep_employed_count >= 2
  AND hd.hd_income_band_sk IN (4, 8, 12)
  AND hd.hd_dep_count <= 5
  AND t.t_hour BETWEEN 8 AND 20
  AND t.t_meal_time = 'Dinner'
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    t.t_hour,
    s.total_sales,
    s.avg_discount,
    s.sales_cnt,
    r.total_return_amt,
    r.total_net_loss
HAVING SUM(s.sales_cnt) > 0
   AND COALESCE(r.total_return_amt, 0) > 0
ORDER BY s.total_sales DESC
LIMIT 100
