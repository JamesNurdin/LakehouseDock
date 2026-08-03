WITH cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_net_loss,
        dd.d_year,
        i.i_brand,
        i.i_item_desc,
        i.i_color,
        i.i_product_name,
        cc.cc_name,
        w.w_warehouse_name,
        cp.cp_type,
        cp.cp_catalog_number
    FROM catalog_returns cr
    JOIN date_dim dd
        ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{3}\\b')
      AND i.i_color LIKE 'Red%'
      AND cp.cp_type LIKE '%monthly%'
)
SELECT
    d_year,
    cc_name,
    i_brand,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_return_quantity) AS total_return_qty,
    count(*) AS return_cnt,
    any_value(concat(cc_name, ' - ', w_warehouse_name)) AS cc_warehouse,
    any_value(regexp_extract(i_product_name, '^(\\w+)', 1)) AS product_prefix,
    any_value(substring(i_item_desc, 1, 30)) AS item_desc_snippet
FROM cr_base
GROUP BY GROUPING SETS (
    (d_year, cc_name),
    (d_year, i_brand),
    (d_year)
)
ORDER BY d_year DESC, total_return_amount DESC
LIMIT 100
