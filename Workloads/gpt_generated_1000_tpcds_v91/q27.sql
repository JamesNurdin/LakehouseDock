WITH sr_agg AS (
    SELECT
        sr_store_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(sr_return_ship_cost) AS total_ship_cost
    FROM store_returns
    WHERE sr_return_ship_cost > 50
      AND sr_return_ship_cost < 900
      AND sr_return_quantity >= 1
      AND sr_return_amt > 0
      AND sr_return_tax >= 0
    GROUP BY sr_store_sk, sr_returned_date_sk
)
SELECT
    store.s_store_id,
    store.s_state,
    d_ret.d_date,
    d_ret.d_day_name,
    web_page.wp_type,
    web_page.wp_image_count,
    sr_agg.total_net_loss,
    sr_agg.return_cnt,
    CASE
        WHEN sr_agg.total_net_loss > 1000 THEN 'High'
        WHEN sr_agg.total_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY store.s_state ORDER BY sr_agg.total_net_loss DESC) AS state_rank,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = store.s_store_sk
          AND sr2.sr_returned_date_sk = sr_agg.sr_returned_date_sk
          AND sr2.sr_return_amt > 100
    ) AS high_return_amt_sum,
    wp_stats.max_image_per_type
FROM sr_agg
JOIN store ON sr_agg.sr_store_sk = store.s_store_sk
JOIN date_dim AS d_ret ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN web_page ON web_page.wp_creation_date_sk = d_ret.d_date_sk
CROSS JOIN LATERAL (
    SELECT MAX(wp2.wp_image_count) AS max_image_per_type
    FROM web_page wp2
    WHERE wp2.wp_type = web_page.wp_type
) AS wp_stats
CROSS JOIN (
    SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3
) AS buckets
WHERE d_ret.d_day_name = 'Monday'
  AND d_ret.d_holiday = 'N'
  AND d_ret.d_fy_week_seq BETWEEN 5 AND 15
  AND store.s_state = 'CA'
  AND web_page.wp_type = 'dynamic'
  AND web_page.wp_image_count >= 3
  AND sr_agg.total_net_loss > (
        SELECT AVG(sr3.sr_net_loss)
        FROM store_returns sr3
        WHERE sr3.sr_store_sk = store.s_store_sk
    )
ORDER BY store.s_state, sr_agg.total_net_loss DESC
LIMIT 100
