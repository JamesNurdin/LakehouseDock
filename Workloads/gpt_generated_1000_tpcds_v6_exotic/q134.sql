WITH total_sales_cte AS (
    SELECT SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
store_sales_agg AS (
    SELECT
        s.s_store_name AS source,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        SUM(sr.sr_return_amt) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS return_rate,
        SUM(ss.ss_ext_sales_price) / (SELECT total_sales FROM total_sales_cte) AS sales_share
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND lower(s.s_store_name) LIKE '%store%'
      AND EXISTS (
          SELECT 1 FROM store_returns sr_check
          WHERE sr_check.sr_item_sk = ss.ss_item_sk
      )
    GROUP BY s.s_store_name, i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
catalog_sales_agg AS (
    SELECT
        cp.cp_type AS source,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
        SUM(cr.cr_return_amount) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS return_rate,
        SUM(cs.cs_ext_sales_price) / (SELECT total_sales FROM total_sales_cte) AS sales_share
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%special%'
      AND regexp_extract(i.i_product_name, '(\\w+)$', 1) = 'End'
    GROUP BY cp.cp_type, i.i_category
    HAVING SUM(cs.cs_ext_sales_price) > 15000
)
SELECT *
FROM (
    SELECT source, category, total_sales, total_returns, return_rate, sales_share
    FROM store_sales_agg
    UNION ALL
    SELECT source, category, total_sales, total_returns, return_rate, sales_share
    FROM catalog_sales_agg
) combined
ORDER BY sales_share DESC
LIMIT 100
