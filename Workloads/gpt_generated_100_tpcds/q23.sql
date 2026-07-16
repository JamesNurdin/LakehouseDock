WITH filtered_dates AS (
    SELECT d_date_sk,
           d_year,
           d_moy,
           d_date
    FROM date_dim
    WHERE d_date >= DATE '2022-01-01' AND d_date <= DATE '2022-12-31'
),
sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS sold_date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_promo_sk AS promo_sk,
           ws.ws_quantity AS quantity,
           ws.ws_ext_discount_amt AS discount_amt,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
)
SELECT i.i_category,
       i.i_brand,
       d.d_year,
       d.d_moy,
       p.p_promo_name,
       SUM(s.quantity) AS total_quantity,
       SUM(s.discount_amt) AS total_discount,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       CASE WHEN SUM(s.quantity) = 0 THEN 0 ELSE SUM(s.discount_amt) / SUM(s.quantity) END AS avg_discount_per_item
FROM sales s
JOIN filtered_dates d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
GROUP BY i.i_category,
         i.i_brand,
         d.d_year,
         d.d_moy,
         p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
