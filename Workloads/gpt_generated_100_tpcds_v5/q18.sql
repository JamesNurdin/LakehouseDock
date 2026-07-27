WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    WHERE ss.ss_ext_discount_amt > 0
      AND ss.ss_coupon_amt < 500
    GROUP BY
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk
)
SELECT DISTINCT
    d.d_date,
    d.d_day_name,
    t.t_hour,
    hd.hd_buy_potential,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.distinct_tickets,
    RANK() OVER (PARTITION BY sa.ss_store_sk ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Regular' END AS day_category
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON sa.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd ON sa.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2020
  AND d.d_qoy = 2
  AND t.t_shift = 'first'
  AND hd.hd_income_band_sk BETWEEN 5 AND 10
ORDER BY sa.total_net_profit DESC, profit_rank
LIMIT 100
