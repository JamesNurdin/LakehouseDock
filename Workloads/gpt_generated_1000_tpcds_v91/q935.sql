WITH sales_data AS (
    SELECT
        d.d_year,
        hd.hd_income_band_sk,
        cc.cc_division,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(ss.ss_quantity) AS total_quantity,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_status
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND cc.cc_country = 'United States'
      AND hd.hd_income_band_sk IN (10, 13)
      AND hd.hd_dep_count > 0
    GROUP BY ROLLUP (d.d_year, hd.hd_income_band_sk, cc.cc_division)
)
SELECT
    sd.d_year,
    sd.hd_income_band_sk,
    sd.cc_division,
    sd.total_net_profit,
    sd.total_sales,
    sd.total_returns,
    sd.profit_status,
    CASE WHEN sd.total_net_profit > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS profit_vs_avg_flag,
    ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_net_profit DESC) AS profit_rank_in_year,
    (SELECT COUNT(*)
        FROM store_returns sr3
        JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
        JOIN household_demographics hd3 ON sr3.sr_hdemo_sk = hd3.hd_demo_sk
        WHERE d3.d_year = sd.d_year
          AND hd3.hd_income_band_sk = sd.hd_income_band_sk
    ) AS returns_count_for_year_income
FROM sales_data sd
ORDER BY sd.d_year DESC, sd.total_net_profit DESC
LIMIT 100
