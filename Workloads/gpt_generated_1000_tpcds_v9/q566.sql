WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        c.c_birth_country,
        i.i_category,
        i.i_brand,
        i.i_rec_start_date,
        i.i_rec_end_date,
        p.p_promo_name,
        p.p_discount_active,
        w.w_state
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_brand = 'BrandX'
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date <= DATE '1999-12-31'
      AND c.c_birth_country IN ('UKRAINE', 'SWITZERLAND')
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
), agg AS (
    SELECT
        c_birth_country,
        i_category,
        i_brand,
        p_promo_name,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(ws_quantity) AS total_quantity
    FROM base
    GROUP BY
        c_birth_country,
        i_category,
        i_brand,
        p_promo_name
    HAVING SUM(ws_net_profit) > 10000
), final AS (
    SELECT
        a.c_birth_country,
        a.i_category,
        a.i_brand,
        a.p_promo_name,
        a.total_sales,
        a.total_profit,
        a.distinct_orders,
        a.total_quantity,
        RANK() OVER (PARTITION BY a.c_birth_country ORDER BY a.total_profit DESC) AS profit_rank,
        SUM(a.total_sales) OVER (PARTITION BY a.c_birth_country) AS sales_by_country,
        (SELECT AVG(total_profit) FROM agg) AS avg_total_profit
    FROM agg a
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_name = a.p_promo_name
          AND p2.p_promo_name LIKE '%Clearance%'
    )
)
SELECT
    c_birth_country,
    i_category,
    i_brand,
    p_promo_name,
    total_sales,
    total_profit,
    distinct_orders,
    total_quantity,
    profit_rank,
    sales_by_country,
    avg_total_profit
FROM final
WHERE profit_rank <= 10
ORDER BY total_profit DESC
LIMIT 100
