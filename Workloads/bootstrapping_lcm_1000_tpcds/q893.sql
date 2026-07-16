WITH agg AS (
    SELECT
        d.d_date AS start_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_market_desc,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        DATE_DIFF('day', d.d_date, end_date.d_date) AS promo_duration_days
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN date_dim end_date
        ON p.p_end_date_sk = end_date.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_market_desc,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        end_date.d_date
)
SELECT
    agg.start_date,
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_name,
    agg.s_market_desc,
    agg.p_promo_name,
    agg.p_discount_active,
    agg.p_cost,
    agg.total_quantity,
    agg.distinct_items,
    agg.promo_duration_days,
    agg.total_quantity * agg.p_cost AS inventory_promo_value,
    RANK() OVER (PARTITION BY agg.s_market_desc ORDER BY agg.total_quantity DESC) AS market_quantity_rank
FROM agg
ORDER BY agg.total_quantity DESC
LIMIT 100
