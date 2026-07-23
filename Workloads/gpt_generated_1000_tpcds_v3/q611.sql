SELECT
    d.d_year,
    d.d_month_seq,
    cd.cd_education_status,
    CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_quantity) AS avg_quantity,
    MAX(ss.ss_ext_discount_amt) AS max_discount,
    MIN(ss.ss_list_price) AS min_list_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 20020 AND 20025
  AND cd.cd_education_status = 'Advanced Degree'
  AND cd.cd_purchase_estimate >= 4000
  AND t.t_sub_shift = 'morning'
  AND t.t_hour BETWEEN 8 AND 12
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
          AND hd.hd_vehicle_count >= 2
          AND ib.ib_lower_bound >= 50000
    )
GROUP BY d.d_year, d.d_month_seq, cd.cd_education_status,
         CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END
ORDER BY total_net_paid DESC
LIMIT 100
