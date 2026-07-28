WITH base AS (
    SELECT
        d.d_year,
        hd.hd_buy_potential,
        i.i_brand,
        t.t_meal_time,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(i.i_current_price) AS avg_price
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                       AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'lunch'
      AND ib.ib_lower_bound >= 10000
      AND i.i_current_price > 50
    GROUP BY GROUPING SETS (
        (d.d_year, hd.hd_buy_potential, i.i_brand, t.t_meal_time),
        (d.d_year, hd.hd_buy_potential, i.i_brand),
        (d.d_year, hd.hd_buy_potential),
        (d.d_year)
    )
)
SELECT
    base.d_year,
    base.hd_buy_potential,
    base.i_brand,
    base.t_meal_time,
    base.total_return_amt,
    base.return_cnt,
    base.avg_price
FROM base
WHERE base.total_return_amt > 1000
ORDER BY base.d_year DESC, base.total_return_amt DESC
LIMIT 100
