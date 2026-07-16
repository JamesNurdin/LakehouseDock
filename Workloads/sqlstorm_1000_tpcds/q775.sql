WITH date_range AS (
    SELECT d_date_sk,
           d_year,
           DATE_TRUNC('month', d_date) AS month_start
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
),
catalog AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           cs.cs_ext_sales_price AS sales,
           cs.cs_net_profit AS profit,
           cs.cs_quantity AS qty,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
),
store AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           ss.ss_ext_sales_price AS sales,
           ss.ss_net_profit AS profit,
           ss.ss_quantity AS qty,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
),
web AS (
    SELECT ws.ws_sold_date_sk AS date_sk,
           i.i_category AS category,
           i.i_class AS class,
           i.i_brand AS brand,
           ws.ws_ext_sales_price AS sales,
           ws.ws_net_profit AS profit,
           ws.ws_quantity AS qty,
           ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
combined AS (
    SELECT d.month_start,
           d.d_year,
           v.category,
           v.class,
           v.brand,
           SUM(v.sales) AS total_sales,
           SUM(v.profit) AS total_profit,
           SUM(v.qty) AS total_qty,
           COUNT(DISTINCT v.promo_sk) AS promo_count
    FROM (
        SELECT * FROM catalog
        UNION ALL
        SELECT * FROM store
        UNION ALL
        SELECT * FROM web
    ) v
    JOIN date_range d ON v.date_sk = d.d_date_sk
    GROUP BY d.month_start, d.d_year, v.category, v.class, v.brand
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY month_start ORDER BY total_sales DESC) AS sales_rank,
           RANK() OVER (PARTITION BY month_start ORDER BY total_profit DESC) AS profit_rank
    FROM combined
)
SELECT month_start,
       d_year,
       category,
       class,
       brand,
       total_sales,
       total_profit,
       total_qty,
       promo_count,
       sales_rank,
       profit_rank,
       (total_sales - LAG(total_sales) OVER (PARTITION BY category ORDER BY month_start))
         / NULLIF(LAG(total_sales) OVER (PARTITION BY category ORDER BY month_start), 0) * 100 AS mom_sales_pct_change
FROM ranked
WHERE sales_rank <= 5
ORDER BY month_start, sales_rank
