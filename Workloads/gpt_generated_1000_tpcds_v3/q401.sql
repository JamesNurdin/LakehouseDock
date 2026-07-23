SELECT *
FROM (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           p.p_promo_id AS promo_id,
           'store' AS channel,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_id

    UNION ALL

    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           p.p_promo_id AS promo_id,
           'web' AS channel,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_id
) AS combined
ORDER BY combined.year,
         combined.month_seq,
         combined.total_profit DESC
LIMIT 100
