WITH sales_agg AS (
    SELECT
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        i.i_category,
        i.i_brand,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MIN(d_sold.d_date) AS first_sale_date,
        MAX(d_sold.d_date) AS last_sale_date
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    CROSS JOIN store s
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      AND (s.s_closed_date_sk IS NULL OR cs.cs_sold_date_sk < s.s_closed_date_sk)
    GROUP BY
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        i.i_category,
        i.i_brand,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    a.s_store_name,
    a.s_city,
    a.p_promo_name,
    a.i_category,
    a.i_brand,
    a.d_year,
    a.d_month_seq,
    a.total_net_paid,
    a.total_net_profit,
    a.order_count,
    a.first_sale_date,
    a.last_sale_date,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_profit DESC) AS profit_rank
FROM sales_agg a
ORDER BY a.total_net_profit DESC
LIMIT 100
