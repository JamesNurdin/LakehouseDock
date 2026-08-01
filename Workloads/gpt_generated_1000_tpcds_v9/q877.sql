WITH avg_price_cte AS (
    SELECT AVG(cs_ext_sales_price) AS avg_price
    FROM catalog_sales
),
sales_active_promo AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        d_sold.d_date AS sold_date,
        sm.sm_type AS ship_type,
        cd.cd_gender AS gender,
        CASE
            WHEN cs.cs_ext_sales_price > (SELECT avg_price FROM avg_price_cte) THEN 'HIGH'
            ELSE 'LOW'
        END AS price_category
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND d_sold.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND cd.cd_dep_count >= 2
),
sales_express_no_promo AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit,
        p.p_promo_name AS promo_name,
        d_sold.d_date AS sold_date,
        sm.sm_type AS ship_type,
        cd.cd_gender AS gender,
        CASE
            WHEN cs.cs_ext_sales_price > (SELECT avg_price FROM avg_price_cte) THEN 'HIGH'
            ELSE 'LOW'
        END AS price_category
    FROM catalog_sales cs
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE (p.p_discount_active <> 'Y' OR p.p_discount_active IS NULL)
      AND d_sold.d_year = 2001
      AND sm.sm_type = 'EXPRESS'
      AND cd.cd_gender = 'F'
)
SELECT
    order_number,
    ext_sales_price,
    net_profit,
    promo_name,
    sold_date,
    ship_type,
    gender,
    price_category
FROM sales_active_promo
UNION ALL
SELECT
    order_number,
    ext_sales_price,
    net_profit,
    promo_name,
    sold_date,
    ship_type,
    gender,
    price_category
FROM sales_express_no_promo
ORDER BY net_profit DESC
LIMIT 100
