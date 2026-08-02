WITH ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_promo_sk,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(ws_ext_discount_amt) AS sum_ws_ext_discount_amt,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        AVG(ws_quantity) AS avg_ws_quantity,
        MIN(ws_quantity) AS min_ws_quantity,
        MAX(ws_quantity) AS max_ws_quantity,
        ARRAY_AGG(DISTINCT ws_web_page_sk) AS ws_web_page_sks_arr
    FROM web_sales
    WHERE ws_web_page_sk = 2133
      AND ws_quantity > 0
    GROUP BY ws_sold_date_sk, ws_promo_sk
)
SELECT
    d_sold.d_date AS sold_date,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    p.p_promo_name,
    ws_agg.sum_ws_net_paid,
    ws_agg.sum_ws_ext_discount_amt,
    ws_agg.order_cnt,
    ws_agg.avg_ws_quantity,
    ws_agg.min_ws_quantity,
    ws_agg.max_ws_quantity,
    ws_exploded.ws_web_page_sk AS exploded_ws_web_page_sk,
    SUM(ws_agg.sum_ws_net_paid) OVER (PARTITION BY p.p_promo_name ORDER BY d_sold.d_date) AS cum_net_paid_by_promo,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws_agg.sum_ws_net_paid DESC) AS promo_rank
FROM ws_agg
JOIN date_dim d_sold ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
CROSS JOIN UNNEST(ws_agg.ws_web_page_sks_arr) AS ws_exploded(ws_web_page_sk)
WHERE d_sold.d_current_quarter = 'Y'
  AND d_sold.d_weekend = 'N'
  AND d_sold.d_dow = 5
  AND p.p_channel_press = 'N'
  AND p.p_channel_event = 'N'
  AND p.p_discount_active = 'Y'
ORDER BY d_sold.d_date DESC, ws_agg.sum_ws_net_paid DESC
LIMIT 100
