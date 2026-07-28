WITH filtered_catalog AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND regexp_like(CAST(cr.cr_return_amount AS varchar), '^[0-9]+\\.[0-9]{2}$')
)
SELECT
    r.r_reason_desc,
    cc.cc_manager,
    mgr.first_name,
    d.d_year,
    SUM(fc.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM filtered_catalog fc
JOIN reason r
    ON fc.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
    ON fc.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
    ON fc.cr_returned_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(cc.cc_manager, '^([^ ]+)') AS first_name
) AS mgr
WHERE r.r_reason_desc LIKE '%damage%'
  AND regexp_like(r.r_reason_desc, '(?i)defect|damage')
  AND cc.cc_manager LIKE '%Burchett%'
  AND fc.cs_quantity > (
        SELECT AVG(ws_quantity)
        FROM web_sales ws
        WHERE ws.ws_sold_date_sk = d.d_date_sk
    )
GROUP BY r.r_reason_desc, cc.cc_manager, mgr.first_name, d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
