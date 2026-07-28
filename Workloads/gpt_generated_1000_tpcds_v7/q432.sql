WITH agg_sales AS (
    SELECT
        i.i_item_id,
        d1.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS store_sales_sum,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_sum,
        SUM(sr.sr_return_amt) AS returns_sum,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_cnt
    FROM store_sales ss
    JOIN date_dim d1
        ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d1.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d1.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d1.d_year = 2001
      AND i.i_brand_id = 2004002
      AND c.c_salutation = 'Mr.'
    GROUP BY i.i_item_id, d1.d_year
)
SELECT
    year,
    AVG(store_sales_sum) AS avg_store_sales,
    AVG(catalog_sales_sum) AS avg_catalog_sales,
    SUM(returns_sum) AS total_returns,
    AVG(inventory_on_hand) AS avg_inventory,
    AVG(web_pages_cnt) AS avg_web_pages
FROM agg_sales
GROUP BY year
HAVING AVG(store_sales_sum) > 1000
   AND SUM(returns_sum) < 5000
   AND AVG(inventory_on_hand) > 0
