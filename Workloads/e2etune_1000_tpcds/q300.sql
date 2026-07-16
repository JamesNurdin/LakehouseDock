WITH filtered_items AS (
    SELECT i_item_sk, i_category, i_brand, i_brand_id, i_color
    FROM item
    WHERE i_color = 'red'
      AND i_brand_id IN (5003002, 1001001)
),
sales_enriched AS (
    SELECT ss_item_sk,
           ss_net_profit,
           ss_quantity,
           ss_ext_discount_amt,
           ss_sold_time_sk
    FROM store_sales
    WHERE ss_net_profit > 0
)
SELECT
    agg.i_category,
    agg.i_brand,
    agg.t_hour,
    agg.t_shift,
    agg.total_net_profit,
    agg.total_quantity,
    agg.avg_discount,
    agg.sales_transactions,
    RANK() OVER (PARTITION BY agg.i_category ORDER BY agg.total_net_profit DESC) AS profit_rank_in_category
FROM (
    SELECT
        i.i_category,
        i.i_brand,
        t.t_hour,
        t.t_shift,
        SUM(s.ss_net_profit) AS total_net_profit,
        SUM(s.ss_quantity) AS total_quantity,
        AVG(s.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_transactions
    FROM filtered_items i
    JOIN sales_enriched s ON i.i_item_sk = s.ss_item_sk
    JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
    GROUP BY
        i.i_category,
        i.i_brand,
        t.t_hour,
        t.t_shift
    HAVING SUM(s.ss_net_profit) > 1000
) agg
ORDER BY agg.total_net_profit DESC
LIMIT 20
