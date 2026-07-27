/*
  Goal: Compare each customer's total net profit and total sales amount for the year 2022 between
  sales that occurred under active promotions and sales that did not, and show the overall average
  discount amount for 2022 as a scalar sub‑query value.
*/
WITH promo_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        SUM(ss.ss_ext_sales_price)   AS total_sales,
        'promo'                       AS sales_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
      AND p.p_discount_active = 'Y'
    GROUP BY c.c_customer_id
),
nonpromo_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        SUM(ss.ss_ext_sales_price)   AS total_sales,
        'nonpromo'                    AS sales_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
      AND (p.p_promo_sk IS NULL OR p.p_discount_active <> 'Y')
    GROUP BY c.c_customer_id
),
combined AS (
    SELECT * FROM promo_sales
    UNION ALL
    SELECT * FROM nonpromo_sales
)
SELECT
    comb.c_customer_id,
    comb.sales_type,
    comb.total_net_profit,
    comb.total_sales,
    (
        SELECT AVG(ss2.ss_ext_discount_amt)
        FROM store_sales ss2
        JOIN date_dim d2
            ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2022
    ) AS avg_discount_2022
FROM combined comb
WHERE comb.total_sales > 0
ORDER BY comb.sales_type, comb.total_net_profit DESC
LIMIT 100
