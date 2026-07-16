WITH agg AS (
    SELECT
        hd.hd_income_band_sk,
        i.i_category,
        COUNT(*) AS cnt,
        AVG(i.i_current_price) AS avg_price,
        SUM(i.i_wholesale_cost) AS total_wholesale,
        MIN(i.i_rec_start_date) AS earliest_item_date,
        MAX(t.t_hour) AS max_hour
    FROM household_demographics hd
    JOIN item i
        ON hd.hd_income_band_sk = i.i_category_id
    JOIN time_dim t
        ON (hd.hd_demo_sk + i.i_item_sk) % 24 = t.t_hour
    WHERE hd.hd_buy_potential IN ('0-500', '501-1000')
      AND i.i_units = 'Cup'
      AND t.t_am_pm = 'PM'
      AND i.i_rec_start_date >= DATE '2020-01-01'
    GROUP BY hd.hd_income_band_sk, i.i_category
    HAVING COUNT(*) > 10
)
SELECT
    hd_income_band_sk,
    i_category,
    cnt,
    avg_price,
    total_wholesale,
    earliest_item_date,
    max_hour,
    ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY avg_price DESC) AS rank_by_price
FROM agg
ORDER BY avg_price DESC
LIMIT 50
