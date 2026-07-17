WITH filtered_returns AS (
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cr_warehouse_sk,
           cr_reason_sk,
           cr_net_loss
    FROM catalog_returns
    WHERE cr_net_loss > 0
)
SELECT
    CONCAT(w.w_city, ', ', w.w_zip) AS warehouse_location,
    SUBSTRING(r.r_reason_id, 1, 4) AS reason_prefix,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM filtered_returns fr
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON fr.cr_item_sk = i.i_item_sk
JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND i.i_item_id LIKE '001%'
  AND LOWER(r.r_reason_desc) LIKE '%size%'
GROUP BY
    CONCAT(w.w_city, ', ', w.w_zip),
    SUBSTRING(r.r_reason_id, 1, 4)
