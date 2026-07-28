WITH returns_filtered AS ( 
    SELECT 
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        i.i_product_name,
        i.i_item_desc,
        r.r_reason_desc,
        cp.cp_description
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2022
      AND regexp_like(i.i_product_name, '^PRO[0-9]{2,}')
      AND cp.cp_description LIKE '%special%'
) 
SELECT 
    rf.r_reason_desc,
    rf.d_year,
    COUNT(*) AS returns_cnt,
    SUM(rf.cr_return_amount) AS total_return_amount,
    SUM(rf.cr_net_loss) AS total_net_loss,
    LISTAGG(rf.i_product_name, ', ') WITHIN GROUP (ORDER BY rf.i_product_name) AS product_names
FROM returns_filtered rf
WHERE NOT EXISTS ( 
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = rf.cr_item_sk
      AND inv.inv_date_sk = rf.cr_returned_date_sk
      AND inv.inv_quantity_on_hand > 0
) 
GROUP BY rf.r_reason_desc, rf.d_year
ORDER BY total_return_amount DESC
LIMIT 100
