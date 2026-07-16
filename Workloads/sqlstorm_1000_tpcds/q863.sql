WITH sales_aggregated AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
), returns_aggregated AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_store_sk AS store_sk,
           sr.sr_item_sk AS item_sk,
           -sr.sr_return_quantity AS quantity,
           -sr.sr_return_amt AS net_paid,
           -sr.sr_net_loss AS net_profit,
           NULL AS promo_sk
    FROM store_returns sr
), combined AS (
    SELECT * FROM sales_aggregated
    UNION ALL
    SELECT * FROM returns_aggregated
)
SELECT d.d_year,
       s.s_store_name,
       i.i_brand,
       SUM(c.quantity) AS total_quantity,
       SUM(c.net_paid) AS total_net_paid,
       SUM(c.net_profit) AS total_net_profit
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN store s ON c.store_sk = s.s_store_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year = 1998
GROUP BY d.d_year, s.s_store_name, i.i_brand
ORDER BY total_net_paid DESC
LIMIT 50
