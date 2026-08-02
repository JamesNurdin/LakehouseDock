SELECT s_store_id,
       s_store_name,
       d_year,
       month_seq,
       total_sales,
       profit_category,
       lower_income_bound
FROM (
    SELECT s.s_store_id,
           s.s_store_name,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High'
                WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
                ELSE 'Low' END AS profit_category,
           ib.ib_lower_bound AS lower_income_bound
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 1999
      AND d.d_month_seq = 1
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = ss.ss_store_sk
      )
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq, ib.ib_lower_bound
    UNION
    SELECT s.s_store_id,
           s.s_store_name,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High'
                WHEN SUM(ss.ss_net_profit) > 0 THEN 'Medium'
                ELSE 'Low' END AS profit_category,
           ib.ib_lower_bound AS lower_income_bound
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 1999
      AND d.d_month_seq = 2
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = ss.ss_store_sk
      )
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq, ib.ib_lower_bound
) AS combined
ORDER BY total_sales DESC
LIMIT 100
