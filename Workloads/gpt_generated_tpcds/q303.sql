WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions,
        COUNT(DISTINCT ss_item_sk) AS distinct_items_sold
    FROM store_sales
    GROUP BY ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_gmt_offset,
    agg.total_sales,
    agg.total_net_paid,
    agg.total_net_profit,
    agg.avg_discount,
    agg.num_transactions,
    agg.distinct_items_sold,
    (agg.total_net_profit / NULLIF(agg.total_sales, 0)) AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank,
    SUM(agg.total_net_profit) OVER (ORDER BY agg.total_net_profit DESC) AS cumulative_profit
FROM store s
JOIN store_sales_agg agg
    ON agg.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
ORDER BY agg.total_net_profit DESC
LIMIT 10
