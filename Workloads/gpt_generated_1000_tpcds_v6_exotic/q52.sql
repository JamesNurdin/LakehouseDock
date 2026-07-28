WITH store_data AS (
   SELECT
       ss.ss_sold_date_sk AS date_sk,
       ss.ss_promo_sk   AS promo_sk,
       ss.ss_ext_sales_price AS sales_amount,
       ss.ss_quantity   AS qty,
       ss.ss_net_profit AS net_profit
   FROM store_sales ss
   WHERE ss.ss_quantity > 0
),
web_data AS (
   SELECT
       ws.ws_sold_date_sk AS date_sk,
       ws.ws_promo_sk   AS promo_sk,
       ws.ws_ext_sales_price AS sales_amount,
       ws.ws_quantity   AS qty,
       ws.ws_net_profit AS net_profit
   FROM web_sales ws
   WHERE ws.ws_quantity > 0
),
union_sales AS (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM web_data
),
sales_by_promo AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       p.p_promo_sk,
       p.p_promo_name,
       SUM(u.sales_amount) AS total_sales,
       SUM(u.qty)          AS total_qty,
       SUM(u.net_profit)   AS total_profit
   FROM union_sales u
   JOIN date_dim d        ON u.date_sk = d.d_date_sk
   JOIN promotion p        ON u.promo_sk = p.p_promo_sk
   LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND p.p_channel_email = 'N'
     AND p.p_channel_radio = 'N'
     AND p.p_promo_name IS NOT NULL
   GROUP BY d.d_year, d.d_month_seq, p.p_promo_sk, p.p_promo_name
),
final_rank AS (
   SELECT
       *,
       RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
       SUM(total_sales) OVER (
           PARTITION BY d_year
           ORDER BY total_sales DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_sales
   FROM sales_by_promo
)
SELECT
   fr.d_year,
   fr.d_month_seq,
   fr.p_promo_sk,
   fr.p_promo_name,
   fr.total_sales,
   fr.total_qty,
   fr.total_profit,
   fr.sales_rank,
   fr.cumulative_sales
FROM final_rank fr
WHERE NOT EXISTS (
   SELECT 1
   FROM store_sales ss
   WHERE ss.ss_promo_sk = fr.p_promo_sk
     AND ss.ss_net_profit < 0
)
ORDER BY fr.total_sales DESC
LIMIT 100
