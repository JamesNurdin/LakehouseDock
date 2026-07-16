WITH agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_city AS city,
        s.s_state AS state,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        AVG(DATE_DIFF('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        MIN(DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
        COUNT(DISTINCT wh.w_warehouse_sk) AS distinct_warehouse_count,
        MAX(wh.w_warehouse_sq_ft) AS max_warehouse_sq_ft,
        CASE
            WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
            WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
            WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS sold_quarter
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    store_id,
    city,
    state,
    promo_id,
    promo_name,
    sold_year,
    sold_month_seq,
    total_net_paid,
    total_net_profit,
    avg_quantity,
    order_count,
    total_ship_cost,
    avg_days_to_ship,
    promo_duration_days,
    distinct_warehouse_count,
    max_warehouse_sq_ft,
    sold_quarter,
    CASE WHEN total_net_paid <> 0 THEN total_net_profit / total_net_paid ELSE NULL END AS net_margin,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_net_paid DESC) AS rn_store_by_sales
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
