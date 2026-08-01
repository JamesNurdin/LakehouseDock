WITH sub1 AS (
    SELECT
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        d_sold.d_year AS year,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MIN(cs.cs_net_profit) AS min_profit,
        MAX(cs.cs_ext_discount_amt) AS max_discount
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_net_paid_inc_ship > 2000
      AND d_sold.d_year = 2001
      AND d_sold.d_dow = 3
      AND p.p_channel_dmail = 'Y'
      AND p.p_promo_sk = 7
    GROUP BY s.s_store_name, p.p_promo_name, d_sold.d_year
),
sub2 AS (
    SELECT
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        d_sold.d_year AS year,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MIN(cs.cs_net_profit) AS min_profit,
        MAX(cs.cs_ext_discount_amt) AS max_discount
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid_inc_ship > 5000
      AND d_sold.d_year = 2002
      AND d_sold.d_dow = 5
      AND p.p_channel_email = 'Y'
      AND p.p_promo_sk = 9
    GROUP BY s.s_store_name, p.p_promo_name, d_sold.d_year
)
SELECT
    store_name,
    promo_name,
    year,
    total_net_paid,
    avg_quantity,
    order_count,
    min_profit,
    max_discount
FROM (
    SELECT store_name, promo_name, year, total_net_paid, avg_quantity, order_count, min_profit, max_discount FROM sub1
    UNION ALL
    SELECT store_name, promo_name, year, total_net_paid, avg_quantity, order_count, min_profit, max_discount FROM sub2
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
