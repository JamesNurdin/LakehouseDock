WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
),
store_details AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_market_desc,
        s.s_gmt_offset,
        s.s_tax_percentage
    FROM store s
)
SELECT
    sd.s_store_name,
    sd.s_state,
    sd.s_city,
    sd.s_market_desc,
    agg.total_quantity,
    agg.total_sales,
    agg.total_discount,
    agg.total_net_paid,
    agg.total_profit,
    agg.avg_sales_price,
    (agg.total_profit / NULLIF(agg.total_sales, 0)) * 100 AS profit_margin_percent,
    (agg.total_discount / NULLIF(agg.total_sales, 0)) * 100 AS discount_percent,
    RANK() OVER (PARTITION BY sd.s_state ORDER BY agg.total_profit DESC) AS profit_rank_state,
    SUM(agg.total_sales) OVER (PARTITION BY sd.s_state) AS state_total_sales,
    SUM(agg.total_profit) OVER (PARTITION BY sd.s_state) AS state_total_profit
FROM store_details sd
JOIN store_sales_agg agg
    ON agg.ss_store_sk = sd.s_store_sk
ORDER BY profit_margin_percent DESC
LIMIT 100
