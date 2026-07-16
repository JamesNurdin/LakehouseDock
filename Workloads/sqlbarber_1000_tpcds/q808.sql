SELECT cr_returned_date_sk,
       cr_returned_time_sk,
       cr_return_quantity,
       cr_return_amount,
       cr_return_tax,
       cr_return_amount + cr_return_tax AS total_return,
       CASE WHEN cr_return_amount > 9.89 THEN 'High'
            WHEN cr_return_amount > 1854.60 THEN 'Medium'
            ELSE 'Low' END AS amount_category,
       CASE WHEN cr_return_quantity = 0 THEN NULL
            ELSE cr_return_amount / cr_return_quantity END AS avg_amount_per_item,
       r_reason_desc,
       CASE r_reason_desc
            WHEN 'Customer Not Satisfied' THEN 'CSAT'
            WHEN 'Item Damaged' THEN 'DAM'
            ELSE 'OTHER' END AS reason_code
FROM catalog_returns
JOIN reason ON catalog_returns.cr_reason_sk = reason.r_reason_sk
WHERE cr_return_quantity > 10
