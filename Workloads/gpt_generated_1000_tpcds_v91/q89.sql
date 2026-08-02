WITH combined_sales AS (
    SELECT DISTINCT
        cs.cs_item_sk AS item_sk,
        dd.d_date AS sale_date,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN date_dim dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2000
      AND cp.cp_department = 'Books'
    UNION ALL
    SELECT DISTINCT
        ws.ws_item_sk AS item_sk,
        dd.d_date AS sale_date,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN date_dim dd
        ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE dd.d_year = 2000
      AND wsite.web_state = 'CA'
),
aggregated_sales AS (
    SELECT
        item_sk,
        sale_date,
        SUM(net_paid) AS total_net_paid
    FROM combined_sales
    GROUP BY item_sk, sale_date
)
SELECT
    item_sk,
    sale_date,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY sale_date ORDER BY total_net_paid DESC) AS sales_rank
FROM aggregated_sales
ORDER BY sale_date DESC, sales_rank
LIMIT 100
