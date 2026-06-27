WITH store_sales_data AS (
    SELECT
        date_dim.d_year,
        promotion.p_promo_name,
        customer_demographics.cd_gender,
        store_sales.ss_net_profit AS net_profit
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE date_dim.d_date >= DATE '2000-01-01' AND date_dim.d_date < DATE '2001-01-01'
),
catalog_sales_data AS (
    SELECT
        date_dim.d_year,
        promotion.p_promo_name,
        customer_demographics.cd_gender,
        catalog_sales.cs_net_profit AS net_profit
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN customer_demographics ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE date_dim.d_date >= DATE '2000-01-01' AND date_dim.d_date < DATE '2001-01-01'
),
web_sales_data AS (
    SELECT
        date_dim.d_year,
        promotion.p_promo_name,
        customer_demographics.cd_gender,
        web_sales.ws_net_profit AS net_profit
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN customer_demographics ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE date_dim.d_date >= DATE '2000-01-01' AND date_dim.d_date < DATE '2001-01-01'
),
combined_sales AS (
    SELECT d_year, p_promo_name, cd_gender, net_profit FROM store_sales_data
    UNION ALL
    SELECT d_year, p_promo_name, cd_gender, net_profit FROM catalog_sales_data
    UNION ALL
    SELECT d_year, p_promo_name, cd_gender, net_profit FROM web_sales_data
)
SELECT
    d_year,
    p_promo_name,
    cd_gender,
    SUM(net_profit) AS total_net_profit
FROM combined_sales
GROUP BY d_year, p_promo_name, cd_gender
ORDER BY total_net_profit DESC
LIMIT 20
