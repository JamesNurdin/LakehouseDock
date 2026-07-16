WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        sold_date.d_year,
        sold_date.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM store_sales ss
    JOIN date_dim AS sold_date
        ON ss.ss_sold_date_sk = sold_date.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = sold_date.d_date_sk
    JOIN date_dim AS closed_date
        ON s.s_closed_date_sk = closed_date.d_date_sk
    JOIN date_dim AS promo_start_date
        ON p.p_start_date_sk = promo_start_date.d_date_sk
    JOIN date_dim AS promo_end_date
        ON p.p_end_date_sk = promo_end_date.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, sold_date.d_year, sold_date.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    total_sales,
    total_profit,
    total_inventory,
    avg_promo_cost,
    promo_count,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
