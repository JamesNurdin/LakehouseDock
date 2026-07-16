WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_category,
        i.i_brand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_quantity > 0
      AND i.i_current_price >= 5
      AND i.i_rec_start_date <= DATE '2023-12-31'
      AND i.i_rec_end_date >= DATE '2023-01-01'
),
agg_sales AS (
    SELECT
        i_category,
        i_brand,
        SUM(ss_quantity) AS total_units_sold,
        SUM(ss_sales_price) AS total_sales_amount,
        SUM(ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_ext_discount_amt / NULLIF(ss_sales_price, 0)) AS avg_discount_rate
    FROM filtered_sales
    GROUP BY GROUPING SETS ((i_category, i_brand), (i_category), ())
    HAVING SUM(ss_net_profit) > 1000
)
SELECT
    COALESCE(i_category, 'ALL') AS category,
    COALESCE(i_brand, 'ALL') AS brand,
    total_units_sold,
    total_sales_amount,
    total_discount_amount,
    total_net_profit,
    avg_discount_rate,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (ORDER BY COALESCE(i_category, 'ALL') ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100
