WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_minute IN (4, 13, 7)                     -- filter on minute
      AND td.t_second >= 10                            -- filter on second
    GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_sold_date_sk
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour = 14                               -- filter on hour
      AND td.t_meal_time = 'Dinner'                    -- filter on meal time
    GROUP BY sr.sr_item_sk, sr.sr_store_sk
)
SELECT
    s.s_store_id,
    i.i_brand,
    i.i_category,
    sa.total_net_paid,
    ra.total_return_amt,
    (sa.total_net_paid - COALESCE(ra.total_return_amt, 0)) AS net_after_returns,
    sa.sales_cnt,
    ra.return_cnt
FROM sales_agg sa
JOIN returns_agg ra
    ON sa.ss_item_sk = ra.sr_item_sk
   AND sa.ss_store_sk = ra.sr_store_sk
JOIN item i
    ON sa.ss_item_sk = i.i_item_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
WHERE i.i_current_price BETWEEN 1.00 AND 5.00               -- price filter
  AND i.i_rec_end_date > DATE '2000-01-01'                 -- rec end date filter
  AND s.s_floor_space > 8000000                            -- floor space filter
  AND s.s_state = 'CA'                                     -- state filter
ORDER BY net_after_returns DESC
LIMIT 100
