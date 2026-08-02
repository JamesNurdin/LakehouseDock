WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        ds.d_year AS sold_year,
        dd.d_holiday,
        dd.d_day_name,
        hd.hd_buy_potential,
        CONCAT(dd.d_holiday, ' - ', dd.d_day_name) AS holiday_day_concat
    FROM catalog_sales cs
    JOIN date_dim ds
        ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN date_dim dd
        ON cs.cs_ship_date_sk = dd.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE dd.d_weekend = 'Y'
      AND dd.d_holiday IS NOT NULL
      AND regexp_like(dd.d_holiday, 'Day$')
      AND dd.d_day_name LIKE 'Mon%'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cs.cs_order_number
            AND wr.wr_returned_date_sk = dd.d_date_sk
      )
)
SELECT
    sold_year,
    hd_buy_potential,
    COUNT(DISTINCT cs_order_number) AS order_count,
    SUM(cs_net_profit) AS total_net_profit,
    MAX(holiday_day_concat) AS example_holiday_day,
    MAX(SUBSTRING(d_day_name, 1, 3)) AS day_abbr,
    (SELECT avg(cs_net_profit) FROM catalog_sales) AS overall_avg_profit,
    CASE
        WHEN GROUPING(sold_year) = 1 AND GROUPING(hd_buy_potential) = 1 THEN 'Grand Total'
        WHEN GROUPING(sold_year) = 0 AND GROUPING(hd_buy_potential) = 1 THEN 'Year Subtotal'
        ELSE 'Detail'
    END AS row_type
FROM sales_filtered
GROUP BY ROLLUP(sold_year, hd_buy_potential)
ORDER BY CASE WHEN sold_year IS NULL THEN 9999 ELSE sold_year END,
         hd_buy_potential
LIMIT 100
