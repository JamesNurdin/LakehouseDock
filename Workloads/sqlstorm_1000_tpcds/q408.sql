WITH filtered_sales AS (
    SELECT ss.ss_sold_date_sk,
           ss.ss_store_sk,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT *
FROM (
    SELECT d.d_year,
           s.s_store_name,
           i.i_category,
           p.p_promo_name,
           SUM(fs.ss_net_paid) AS total_net_paid,
           SUM(fs.ss_net_profit) AS total_net_profit,
           COUNT(DISTINCT fs.ss_item_sk) AS unique_items_sold,
           RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(fs.ss_net_paid) DESC) AS sales_rank
    FROM filtered_sales fs
    JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON fs.ss_store_sk = s.s_store_sk
    JOIN item i ON fs.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, s.s_store_name, i.i_category, p.p_promo_name
) ranked
WHERE ranked.sales_rank <= 5
ORDER BY ranked.total_net_paid DESC
LIMIT 100
