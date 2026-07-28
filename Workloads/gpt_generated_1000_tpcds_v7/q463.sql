WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IS NOT NULL
)
SELECT
    d.d_year,
    i.i_brand,
    r.r_reason_desc,
    w.web_state,
    SUM(base.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(base.cr_return_quantity) AS avg_return_qty,
    MIN(base.cr_return_tax) AS min_return_tax,
    MAX(base.cr_return_amt_inc_tax) AS max_return_inc_tax
FROM base
JOIN date_dim d ON base.cr_returned_date_sk = d.d_date_sk
JOIN item i ON base.cr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
JOIN reason r ON base.cr_reason_sk = r.r_reason_sk
JOIN customer c ON base.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON base.cr_refunded_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND r.r_reason_desc LIKE '%gift%'
  AND w.web_tax_percentage < 0.07
GROUP BY d.d_year, i.i_brand, r.r_reason_desc, w.web_state
ORDER BY total_return_amount DESC
LIMIT 100
