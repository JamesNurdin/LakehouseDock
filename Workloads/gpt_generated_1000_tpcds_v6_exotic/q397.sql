WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_item_sk,
        r.r_reason_desc,
        d.d_year,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        cs.cs_net_paid
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND i.i_item_desc LIKE '%steel%'
)
SELECT
    d_year,
    r_reason_desc,
    i_brand,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    SUM(cs_net_paid) AS total_sales_amount,
    COUNT(*) AS return_cnt,
    CONCAT(r_reason_desc, ' - ', i_brand) AS reason_brand_concat,
    SUBSTRING(MAX(i_item_desc), 1, 15) AS short_item_desc
FROM filtered_returns
GROUP BY ROLLUP (d_year, r_reason_desc, i_brand)
ORDER BY d_year ASC NULLS LAST,
         r_reason_desc ASC NULLS LAST,
         i_brand ASC NULLS LAST
LIMIT 100
