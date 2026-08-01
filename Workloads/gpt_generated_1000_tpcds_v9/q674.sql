WITH filtered AS (
    SELECT
        regexp_extract(i.i_product_name, '(\\d{4})', 1) AS prod_year,
        cp.cp_type AS page_type,
        cr.cr_return_amount,
        cs.cs_net_profit,
        i.i_item_id,
        i.i_color,
        concat(i.i_item_id, '-', i.i_color) AS item_code,
        i.i_product_name AS product_name
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_product_name, '\\d{4}')
      AND cp.cp_description LIKE '%Special%'
      AND d_ret.d_year = 2020
      AND r.r_reason_desc IS NOT NULL
      AND regexp_like(r.r_reason_desc, '(?i)defect|damage')
)
SELECT
    prod_year,
    page_type,
    item_code,
    substr(sample_product_name, 1, 10) AS short_name,
    total_return_amount,
    total_net_profit,
    return_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS row_num
FROM (
    SELECT
        prod_year,
        page_type,
        item_code,
        MIN(product_name) AS sample_product_name,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS return_cnt
    FROM filtered
    GROUP BY prod_year, page_type, item_code
) agg
ORDER BY row_num
LIMIT 100
