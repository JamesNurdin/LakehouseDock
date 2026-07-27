WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_sales_price > 20
      AND cs.cs_net_profit IS NOT NULL
)
SELECT
    w.w_city,
    cd.cd_gender,
    d_sold.d_year,
    t.t_hour,
    SUM(f.cs_net_paid)                     AS total_net_paid,
    AVG(f.cs_sales_price)                  AS avg_sales_price,
    COUNT(*)                               AS sales_cnt,
    SUM(CASE WHEN f.cs_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_cnt,
    CASE 
        WHEN SUM(f.cs_net_profit) > 0 THEN 'Overall Profitable'
        ELSE 'Overall Loss'
    END                                   AS profit_status
FROM filtered_sales f
JOIN date_dim d_sold
  ON f.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
  ON f.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
  ON f.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
  ON f.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE d_sold.d_year = 2001
  AND d_sold.d_month_seq BETWEEN 1200 AND 1211
  AND t.t_am_pm = 'PM'
  AND w.w_city = 'Salem'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
          AND cs2.cs_net_paid > 1000
        LIMIT 1
   )
GROUP BY ROLLUP (w.w_city, cd.cd_gender, d_sold.d_year, t.t_hour)
HAVING SUM(f.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
