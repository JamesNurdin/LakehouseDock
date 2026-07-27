WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        MIN(ss.ss_promo_sk) AS promo_sk,
        MIN(ss.ss_ticket_number) AS ticket_number,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_quantity) AS avg_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        i.i_units = 'Each'
        AND s.s_market_id IN (3, 6)
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
)
SELECT
    s.s_store_name,
    i.i_product_name,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    sa.avg_qty
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_promo_sk = sa.promo_sk
      AND p.p_item_sk = i.i_item_sk
      AND p.p_discount_active = 'Y'
)
AND EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_ticket_number = sa.ticket_number
      AND sr.sr_store_sk = s.s_store_sk
      AND sr.sr_return_quantity > 0
)
ORDER BY sa.total_profit DESC
LIMIT 100
