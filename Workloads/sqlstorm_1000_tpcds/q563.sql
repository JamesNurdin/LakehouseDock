WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
),
aggregated AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           SUM(su.quantity) AS total_quantity,
           SUM(su.net_paid) AS total_sales,
           SUM(su.net_profit) AS total_profit,
           ROUND(100.0 * SUM(su.net_profit) / NULLIF(SUM(su.net_paid), 0), 2) AS profit_margin_pct
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
    HAVING SUM(su.quantity) > 1000
)
SELECT a.d_year,
       a.d_month_seq,
       a.i_category,
       a.i_brand,
       a.total_quantity,
       a.total_sales,
       a.total_profit,
       a.profit_margin_pct,
       ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.d_year, a.total_profit DESC
LIMIT 100
