WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank_per_item
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category_id = 10
      AND w.web_tax_percentage >= 0.05
      AND p.p_channel_tv = 'N'
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    w.web_name,
    p.p_promo_name,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    sa.total_sales,
    sa.total_tax,
    sa.total_profit,
    DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amount DESC) AS return_year_rank,
    ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS overall_sales_rank
FROM sales_agg sa
JOIN catalog_returns cr ON cr.cr_item_sk = sa.ws_item_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON sa.ws_item_sk = i.i_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_site w ON sa.ws_web_site_sk = w.web_site_sk
JOIN promotion p ON sa.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON sa.ws_web_page_sk = wp.wp_web_page_sk
WHERE cr.cr_return_amount > 0
  AND c.c_birth_month = 7
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 0
        LIMIT 1
      )
ORDER BY sa.total_sales DESC
LIMIT 100
