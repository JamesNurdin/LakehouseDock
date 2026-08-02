WITH cat_sales AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CONCAT('Catalog_', COALESCE(CAST(p.p_promo_id AS VARCHAR), '0')) AS source_tag,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{3}')
      AND p.p_promo_name IS NOT NULL
      AND p.p_promo_name LIKE '%Discount%'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr
          WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id, c.c_customer_sk, d.d_year, d.d_month_seq, p.p_promo_id, p.p_promo_name
),
web_sales_agg AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CONCAT('Web_', substr(wp.wp_url, 1, 15)) AS source_tag,
        wp.wp_type AS promo_name
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE REGEXP_EXTRACT(i.i_item_desc, '(\\d{4})') IS NOT NULL
      AND wp.wp_url LIKE 'http://%/product%'
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id, c.c_customer_sk, d.d_year, d.d_month_seq, wp.wp_url, wp.wp_type
)
SELECT
    final.c_customer_id,
    final.d_year,
    final.d_month_seq,
    SUM(final.sales_amount) AS total_sales,
    SUM(final.order_cnt) AS total_orders,
    COUNT(DISTINCT final.source_tag) AS distinct_sources,
    MAX(final.promo_name) AS example_promo
FROM (
    SELECT c_customer_id, d_year, d_month_seq, sales_amount, order_cnt, source_tag, promo_name
    FROM cat_sales
    UNION
    SELECT c_customer_id, d_year, d_month_seq, sales_amount, order_cnt, source_tag, promo_name
    FROM web_sales_agg
) AS final
GROUP BY final.c_customer_id, final.d_year, final.d_month_seq
HAVING SUM(final.sales_amount) > 10000
ORDER BY total_sales DESC
LIMIT 100
