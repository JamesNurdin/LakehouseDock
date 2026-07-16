SELECT
    store_city,
    store_state,
    promo_name,
    channel_catalog,
    sales_year,
    sales_month,
    shipping_date,
    promo_start_date,
    promo_end_date,
    total_net_paid,
    total_discount,
    avg_quantity,
    distinct_orders,
    RANK() OVER (PARTITION BY store_city, sales_year ORDER BY total_net_paid DESC) AS net_paid_rank
FROM (
    SELECT
        s.s_city AS store_city,
        s.s_state AS store_state,
        p.p_promo_name AS promo_name,
        p.p_channel_catalog AS channel_catalog,
        d_sold.d_year AS sales_year,
        d_sold.d_month_seq AS sales_month,
        d_ship.d_date AS shipping_date,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_net_paid > 0
    GROUP BY
        s.s_city,
        s.s_state,
        p.p_promo_name,
        p.p_channel_catalog,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_date,
        d_start.d_date,
        d_end.d_date
) agg
ORDER BY total_net_paid DESC
LIMIT 100
