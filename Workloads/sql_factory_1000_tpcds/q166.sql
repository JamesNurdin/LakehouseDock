WITH daily_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date,
        ws.ws_web_page_sk AS web_page_id,
        ws.ws_promo_sk AS promo_sk,
        SUM(ws.ws_net_profit) AS daily_net_profit,
        COUNT(*) AS daily_txn_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 20230101
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, ws.ws_promo_sk
)
SELECT
    d.sale_date,
    d.web_page_id,
    d.daily_net_profit,
    d.daily_txn_count,
    SUM(d.daily_net_profit) OVER (
        PARTITION BY d.web_page_id
        ORDER BY d.sale_date
        ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
    ) AS moving_sum_14d,
    ROW_NUMBER() OVER (PARTITION BY d.sale_date ORDER BY d.daily_txn_count DESC) AS txn_rank,
    COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
    CASE
        WHEN d.daily_net_profit > 15000 THEN 'High'
        WHEN d.daily_net_profit BETWEEN 8000 AND 15000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM daily_sales d
LEFT JOIN promotion p ON d.promo_sk = p.p_promo_sk
ORDER BY d.sale_date DESC, d.web_page_id
