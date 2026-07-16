WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_ext_sales_price AS ext_sales_price,
           cs_net_profit AS net_profit,
           'catalog' AS channel,
           cs_promo_sk AS promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_ext_sales_price AS ext_sales_price,
           ss_net_profit AS net_profit,
           'store' AS channel,
           ss_promo_sk AS promo_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_ext_sales_price AS ext_sales_price,
           ws_net_profit AS net_profit,
           'web' AS channel,
           ws_promo_sk AS promo_sk
    FROM web_sales
),
agg AS (
    SELECT d.d_year AS d_year,
           s.channel AS channel,
           i.i_category AS i_category,
           i.i_brand AS i_brand,
           p.p_promo_name AS p_promo_name,
           SUM(s.quantity) AS total_quantity,
           SUM(s.ext_sales_price) AS total_sales,
           SUM(s.net_profit) AS total_profit
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY d.d_year, s.channel, i.i_category, i.i_brand, p.p_promo_name
)
SELECT d_year,
       channel,
       i_category,
       i_brand,
       p_promo_name,
       total_quantity,
       total_sales,
       total_profit,
       ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, channel, sales_rank
LIMIT 200
