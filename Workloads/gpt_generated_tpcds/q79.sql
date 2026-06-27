WITH store_sales_enriched AS (
    SELECT
        d_sale.d_date AS sale_date,
        i.i_category,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS sales_price,
        p.p_promo_name,
        p.p_cost
    FROM store_sales ss
    JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_year = 2022
      AND d_sale.d_date >= d_start.d_date
      AND d_sale.d_date <= d_end.d_date
      AND p.p_discount_active = 'Y'
),
catalog_sales_enriched AS (
    SELECT
        d_sale.d_date AS sale_date,
        i.i_category,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS sales_price,
        p.p_promo_name,
        p.p_cost
    FROM catalog_sales cs
    JOIN date_dim d_sale ON cs.cs_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_year = 2022
      AND d_sale.d_date >= d_start.d_date
      AND d_sale.d_date <= d_end.d_date
      AND p.p_discount_active = 'Y'
),
web_sales_enriched AS (
    SELECT
        d_sale.d_date AS sale_date,
        i.i_category,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_sales_price AS sales_price,
        p.p_promo_name,
        p.p_cost
    FROM web_sales ws
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sale.d_year = 2022
      AND d_sale.d_date >= d_start.d_date
      AND d_sale.d_date <= d_end.d_date
      AND p.p_discount_active = 'Y'
),
combined_sales AS (
    SELECT sale_date, i_category, net_profit, sales_price, p_promo_name, p_cost
    FROM store_sales_enriched
    UNION ALL
    SELECT sale_date, i_category, net_profit, sales_price, p_promo_name, p_cost
    FROM catalog_sales_enriched
    UNION ALL
    SELECT sale_date, i_category, net_profit, sales_price, p_promo_name, p_cost
    FROM web_sales_enriched
)
SELECT
    i_category,
    EXTRACT(month FROM sale_date) AS month,
    SUM(net_profit) AS total_net_profit,
    SUM(sales_price) AS total_sales_price,
    AVG(p_cost) AS avg_promo_cost
FROM combined_sales
GROUP BY
    i_category,
    EXTRACT(month FROM sale_date)
ORDER BY
    i_category,
    month
