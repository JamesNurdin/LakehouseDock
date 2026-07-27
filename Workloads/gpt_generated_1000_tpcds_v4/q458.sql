WITH store_ret AS (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(sr.sr_return_amt) AS total_return_amount,
           SUM(sr.sr_return_quantity) AS total_return_quantity,
           'store' AS source
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 20
      AND sr.sr_return_tax > 20
    GROUP BY r.r_reason_desc
),
catalog_ret AS (
    SELECT r.r_reason_desc AS reason_desc,
           SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
           SUM(cr.cr_return_quantity) AS total_return_quantity,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_net_loss > 0
    GROUP BY r.r_reason_desc
)
SELECT reason_desc, total_return_amount, total_return_quantity, source
FROM store_ret
UNION ALL
SELECT reason_desc, total_return_amount, total_return_quantity, source
FROM catalog_ret
ORDER BY total_return_amount DESC
LIMIT 100
