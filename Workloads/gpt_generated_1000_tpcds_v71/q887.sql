/*
Goal: Identify, for each year‑month, the net profit contributed by catalog sales of items whose product name contains a two‑letter followed by three‑digit code (e.g., 'AB123'). Only include sales where the catalog page description mentions "new" and where the order has at least one returned item. The result shows aggregated profit, sales, distinct page categories and promotions, and a formatted code string.
*/
WITH sales_with_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_item_sk,
        i.i_product_name,
        cp.cp_catalog_page_sk,
        cp.cp_description,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        REGEXP_EXTRACT(i.i_product_name, '([A-Z]{2}[0-9]{3})') AS prod_code,
        cp.cp_department || '-' || cp.cp_type AS page_category
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(i.i_product_name, '[A-Z]{2}[0-9]{3}')
      AND cp.cp_description LIKE '%new%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
            AND cr.cr_return_quantity > 0
      )
)
SELECT
    d_year,
    d_month_seq,
    prod_code,
    COUNT(DISTINCT page_category) AS distinct_page_categories,
    COUNT(DISTINCT p_promo_name) AS distinct_promotions,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    CONCAT('Code-', prod_code) AS formatted_code
FROM sales_with_returns
GROUP BY d_year, d_month_seq, prod_code
HAVING SUM(cs_net_profit) > 1000
ORDER BY d_year, d_month_seq, prod_code
