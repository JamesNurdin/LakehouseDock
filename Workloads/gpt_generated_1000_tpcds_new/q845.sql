WITH agg_returns AS (
    SELECT
        sr_store_sk,
        sr_item_sk,
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_fee) AS avg_fee,
        COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_fee > 10
      AND sr_refunded_cash < 500
      AND sr_return_amt_inc_tax > 0
      AND sr_return_ship_cost BETWEEN 0 AND 50
    GROUP BY sr_store_sk, sr_item_sk, sr_return_time_sk
),
item_info AS (
    SELECT i_item_sk,
           i_product_name,
           i_brand,
           i_category,
           i_current_price
    FROM item
    WHERE i_current_price > 5
      AND i_brand_id IN (
          SELECT i_brand_id FROM item WHERE i_brand = 'Brand#12' LIMIT 1
      )
      AND i_category = 'Sports'
      AND i_color = 'Red'
      AND i_size = 'M'
),
sub1 AS (
    SELECT
        s.s_store_name,
        i.i_product_name,
        t.t_hour,
        agg.total_return_amt,
        agg.avg_fee,
        CASE WHEN agg.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        SUM(agg.total_return_amt) OVER (
            PARTITION BY s.s_store_name
            ORDER BY t.t_hour
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return,
        (SELECT MAX(sr_fee) FROM store_returns sr3 WHERE sr3.sr_store_sk = s.s_store_sk) AS max_fee_store
    FROM agg_returns agg
    JOIN item_info i ON agg.sr_item_sk = i.i_item_sk
    JOIN store s ON agg.sr_store_sk = s.s_store_sk
    FULL OUTER JOIN time_dim t ON agg.sr_return_time_sk = t.t_time_sk
    WHERE EXISTS (
            SELECT 1 FROM store_returns sr4
            WHERE sr4.sr_store_sk = s.s_store_sk AND sr4.sr_fee > 50
          )
      AND s.s_state = 'CA'
      AND t.t_minute IN (2, 10, 15)
),
sub2 AS (
    SELECT
        s.s_store_name,
        i.i_product_name,
        t.t_hour,
        agg.total_return_amt,
        agg.avg_fee,
        CASE WHEN agg.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        SUM(agg.total_return_amt) OVER (
            PARTITION BY s.s_store_name
            ORDER BY t.t_hour
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return,
        (SELECT MAX(sr_fee) FROM store_returns sr3 WHERE sr3.sr_store_sk = s.s_store_sk) AS max_fee_store
    FROM agg_returns agg
    JOIN item_info i ON agg.sr_item_sk = i.i_item_sk
    JOIN store s ON agg.sr_store_sk = s.s_store_sk
    FULL OUTER JOIN time_dim t ON agg.sr_return_time_sk = t.t_time_sk
    WHERE EXISTS (
            SELECT 1 FROM store_returns sr4
            WHERE sr4.sr_store_sk = s.s_store_sk AND sr4.sr_fee > 30
          )
      AND s.s_state = 'TX'
      AND t.t_minute IN (3, 19)
)
SELECT
    u.s_store_name,
    u.return_level,
    COUNT(*) AS num_rows,
    SUM(u.total_return_amt) AS sum_return_amt,
    AVG(u.avg_fee) AS avg_fee_overall,
    MAX(u.max_fee_store) AS max_fee_seen
FROM (
    SELECT * FROM sub1
    UNION DISTINCT
    SELECT * FROM sub2
) u
GROUP BY u.s_store_name, u.return_level
ORDER BY sum_return_amt DESC
LIMIT 100
