WITH ws_agg AS (
    SELECT
        ws_sold_time_sk,
        COUNT(*) AS order_cnt,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_promo_sk) AS distinct_promos,
        AVG(ws_coupon_amt) AS avg_coupon_amt
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_promo_sk IN (143, 402, 804)
      AND ws_ship_customer_sk = 9866274
      AND ws_coupon_amt > (
          SELECT MIN(ws_coupon_amt)
          FROM web_sales
          WHERE ws_ship_customer_sk = 2087757
      )
    GROUP BY ws_sold_time_sk
)
SELECT
    t.t_sub_shift,
    t.t_shift,
    CASE WHEN t.t_am_pm = 'PM' THEN 'Evening' ELSE 'Day' END AS period,
    ws_agg.order_cnt,
    ws_agg.total_net_paid,
    ws_agg.distinct_promos,
    ws_agg.avg_coupon_amt,
    MIN(ws_agg.total_net_paid) OVER (PARTITION BY t.t_sub_shift) AS min_net_paid_by_subshift
FROM ws_agg
JOIN time_dim t
    ON ws_agg.ws_sold_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND t.t_sub_shift = 'morning'
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
