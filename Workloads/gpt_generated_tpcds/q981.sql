WITH sales_month_category AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        i.i_category AS category,
        sum(cs.cs_net_paid) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit,
        sum(cs.cs_ext_discount_amt) AS total_discount,
        sum(cs.cs_ext_ship_cost) AS total_ship_cost,
        sum(cs.cs_quantity) AS total_quantity,
        count(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim sd_start
        ON p.p_start_date_sk = sd_start.d_date_sk
    JOIN date_dim sd_end
        ON p.p_end_date_sk = sd_end.d_date_sk
    WHERE d.d_date >= sd_start.d_date
      AND d.d_date <= sd_end.d_date
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
sales_with_rank AS (
    SELECT
        month_start,
        category,
        total_sales,
        total_profit,
        total_discount,
        total_ship_cost,
        total_quantity,
        distinct_orders,
        row_number() OVER (PARTITION BY month_start ORDER BY total_profit DESC) AS profit_rank
    FROM sales_month_category
)
SELECT
    month_start,
    category,
    total_sales,
    total_profit,
    total_discount,
    total_ship_cost,
    total_quantity,
    distinct_orders,
    profit_rank
FROM sales_with_rank
WHERE profit_rank <= 5
ORDER BY month_start DESC, profit_rank
