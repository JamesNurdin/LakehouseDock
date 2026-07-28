/*
Goal: Calculate total sales and profit by item category, brand and promotion channel details that mention “high” or “sudden”, filter for products whose name starts with “A”, extract the first word from the channel description, rank categories by profit, and include subtotal rows using ROLLUP.
*/
WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_channel_details,
        regexp_extract(p.p_channel_details, '(\\w+)', 1) AS channel_word,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit,
        count(DISTINCT ss.ss_ticket_number) AS orders
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_channel_details, '(?i)high|sudden')
      AND i.i_product_name LIKE 'A%'
    GROUP BY ROLLUP (i.i_category, i.i_brand, p.p_channel_details)
)
SELECT
    i_category,
    i_brand,
    p_channel_details,
    channel_word,
    total_sales,
    total_profit,
    orders,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY i_category ASC NULLS LAST,
         i_brand ASC NULLS LAST,
         total_profit DESC
LIMIT 100
