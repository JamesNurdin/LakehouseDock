WITH daily_sales AS (
    SELECT
        ws_sold_date_sk,
        ws_promo_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_list_price) AS avg_list_price
    FROM web_sales
    WHERE ws_net_paid > 0
    GROUP BY ws_sold_date_sk, ws_promo_sk
)
SELECT
    p.p_promo_name,
    p.p_channel_details,
    ds.ws_sold_date_sk AS sale_date_sk,
    ds.total_net_paid,
    ds.total_discount,
    ds.total_quantity,
    ds.avg_list_price,
    RANK() OVER (PARTITION BY ds.ws_sold_date_sk ORDER BY ds.total_net_paid DESC) AS daily_promo_rank
FROM daily_sales ds
JOIN promotion p
    ON ds.ws_promo_sk = p.p_promo_sk
WHERE p.p_channel_tv = 'N'
  AND p.p_start_date_sk IN (2450164, 2450118, 2450675)
  AND p.p_promo_id LIKE 'AAAAAAA%'
ORDER BY ds.ws_sold_date_sk, daily_promo_rank
LIMIT 100
