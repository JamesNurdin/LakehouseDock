WITH sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        concat(CAST(d.d_year AS VARCHAR), '-', lpad(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
        i.i_category,
        cd.cd_gender,
        sm.sm_type AS ship_mode,
        ws.ws_bill_customer_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
)
SELECT
    year_month,
    i_category,
    cd_gender,
    ship_mode,
    COUNT(DISTINCT ws_bill_customer_sk) AS distinct_customers,
    COUNT(DISTINCT ws_promo_sk) AS distinct_promotions,
    COUNT(*) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_discount_amt) AS total_discount,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_ext_ship_cost) AS avg_ship_cost
FROM sales
GROUP BY year_month, i_category, cd_gender, ship_mode
ORDER BY year_month, i_category, cd_gender, ship_mode
