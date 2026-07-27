WITH sales_agg AS (
    SELECT
        i.i_item_id      AS item_id,
        i.i_brand        AS brand,
        d_sold.d_year    AS sales_year,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ss.ss_quantity > 5
      AND wsite.web_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_type = 'Home'
          )
    GROUP BY i.i_item_id, i.i_brand, d_sold.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 1000
)
SELECT *
FROM (
    SELECT
        item_id,
        brand,
        sales_year,
        store_sales_total,
        web_sales_total,
        (store_sales_total + web_sales_total) AS total_sales,
        RANK() OVER (ORDER BY (store_sales_total + web_sales_total) DESC) AS sales_rank,
        SUM((store_sales_total + web_sales_total)) OVER (
            PARTITION BY sales_year
            ORDER BY (store_sales_total + web_sales_total) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales_year
    FROM sales_agg
) t
WHERE total_sales > (
    SELECT AVG(store_sales_total + web_sales_total)
    FROM sales_agg
)
ORDER BY total_sales DESC
LIMIT 100
