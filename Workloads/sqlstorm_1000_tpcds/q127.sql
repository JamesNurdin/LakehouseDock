WITH sales_union AS (
    SELECT cs_sold_date_sk AS sold_date_sk, cs_item_sk AS item_sk, cs_quantity AS quantity, cs_net_paid AS net_paid, cs_net_profit AS net_profit, cs_promo_sk AS promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, ss_net_profit, ss_promo_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid, ws_net_profit, ws_promo_sk
    FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       p.p_promo_name,
       SUM(su.net_paid) AS total_net_paid,
       SUM(su.net_profit) AS total_net_profit,
       COUNT(*) AS num_sales
FROM sales_union su
JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
JOIN item i ON su.item_sk = i.i_item_sk
LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND i.i_category = 'Sports'
GROUP BY d.d_year, i.i_category, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
