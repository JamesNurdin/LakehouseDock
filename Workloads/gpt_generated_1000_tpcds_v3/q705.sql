WITH sales_data AS (
    SELECT
        store.s_store_id AS s_store_id,
        store.s_store_name AS s_store_name,
        promotion.p_promo_id AS p_promo_id,
        promotion.p_promo_name AS p_promo_name,
        CONCAT(store.s_store_name, ' - ', promotion.p_promo_name) AS store_promo,
        regexp_extract(promotion.p_channel_details, '([A-Za-z]+) communities') AS channel_keyword,
        store_sales.ss_net_profit,
        store_sales.ss_ticket_number,
        store_sales.ss_sold_date_sk,
        store.s_store_sk
    FROM store_sales
    JOIN store ON store_sales.ss_store_sk = store.s_store_sk
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2001
      AND store.s_store_name LIKE '%Market%'
      AND regexp_like(promotion.p_channel_details, '(?i)communities')
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
          WHERE sr.sr_store_sk = store.s_store_sk
            AND sr.sr_ticket_number = store_sales.ss_ticket_number
            AND r.r_reason_desc LIKE '%job%'
      )
)
SELECT
    s_store_id,
    s_store_name,
    p_promo_id,
    p_promo_name,
    store_promo,
    channel_keyword,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_ticket_number) AS num_sales
FROM sales_data
GROUP BY
    s_store_id,
    s_store_name,
    p_promo_id,
    p_promo_name,
    store_promo,
    channel_keyword
HAVING
    SUM(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales)
ORDER BY total_net_profit DESC
LIMIT 100
