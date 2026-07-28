WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_ext_discount_amt > 1000                         -- predicate 1
      AND ws.ws_quantity >= 2                                   -- predicate 2
      AND NOT EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
            AND wp2.wp_autogen_flag = 'Y'                      -- anti‑join predicate
      )
),
joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        wp.wp_max_ad_count,
        fs.ws_ext_discount_amt,
        fs.ws_ext_sales_price,
        fs.ws_net_profit
    FROM filtered_sales fs
    JOIN date_dim d ON fs.ws_sold_date_sk = d.d_date_sk       -- join rule 1
    JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk -- join rule 2
    WHERE d.d_year BETWEEN 2000 AND 2002                        -- predicate 3
      AND wp.wp_max_ad_count <= 3                               -- predicate 4
      AND wp.wp_type IN ('home', 'product')                     -- predicate 5
),
agg AS (
    SELECT
        d_year,
        wp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM joined
    GROUP BY ROLLUP (d_year, wp_type)                         -- grouping set
)
SELECT
    d_year,
    wp_type,
    total_sales,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
WHERE d_year IS NOT NULL                                          -- exclude grand total row
ORDER BY d_year ASC, sales_rank ASC
LIMIT 100
