WITH sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_discount_amt > 0
    GROUP BY ss_item_sk
),
brand_category_sales AS (
    SELECT
        i.i_brand,
        i.i_category,
        sa.total_net_profit,
        sa.total_quantity,
        sa.avg_discount
    FROM sales_agg sa
    JOIN item i
      ON sa.ss_item_sk = i.i_item_sk
    WHERE i.i_category IN ('Women', 'Men')
),
agg_brand_category AS (
    SELECT
        i_brand,
        i_category,
        SUM(total_net_profit) AS brand_category_net_profit,
        SUM(total_quantity) AS brand_category_quantity,
        AVG(avg_discount) AS brand_category_avg_discount
    FROM brand_category_sales
    GROUP BY i_brand, i_category
    HAVING SUM(total_net_profit) > 10000
)
SELECT
    i_brand,
    i_category,
    brand_category_net_profit,
    brand_category_quantity,
    brand_category_avg_discount,
    RANK() OVER (PARTITION BY i_category ORDER BY brand_category_net_profit DESC) AS profit_rank
FROM agg_brand_category
ORDER BY i_category, profit_rank
LIMIT 20
