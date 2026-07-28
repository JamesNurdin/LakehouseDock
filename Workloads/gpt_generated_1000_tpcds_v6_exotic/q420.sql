/* Goal: Identify catalog pages with the highest total returned amount in 2001 for items whose description contains the word “blue” and a two‑letter‑followed‑by‑two‑digit code, and where the return reason starts with “duplicate”. */
WITH filtered_returns AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        i.i_item_desc,
        cr.cr_return_amount,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '\\b[A-Z]{2}[0-9]{2}\\b')
      AND i.i_item_desc LIKE '%blue%'
      AND regexp_like(r.r_reason_desc, '^duplicate')
)
SELECT
    cp_department,
    cp_catalog_number,
    substring(i_item_desc, 1, 20) AS short_item_desc,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount
FROM filtered_returns
GROUP BY
    cp_department,
    cp_catalog_number,
    substring(i_item_desc, 1, 20)
ORDER BY total_return_amount DESC
LIMIT 100
