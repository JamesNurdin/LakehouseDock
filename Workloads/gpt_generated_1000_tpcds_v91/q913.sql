SELECT
    cr.cr_order_number,
    d_ret.d_date,
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    s.s_market_desc,
    wp.wp_url,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS amount_rank,
    AVG(cr.cr_return_amount) OVER (PARTITION BY cp.cp_department ORDER BY d_ret.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_return,
    (SELECT MAX(cr3.cr_return_amount) FROM catalog_returns cr3) AS max_return_amount_overall,
    u.url_segment
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cp_start.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
CROSS JOIN UNNEST(SPLIT(wp.wp_url, '/')) AS u(url_segment)
WHERE d_ret.d_year = 1999
  AND d_ret.d_month_seq >= 12
  AND cp.cp_department IN ('Sports', 'Books')
  AND cp.cp_type = 'TYPE1'
  AND cr.cr_return_amount > 100.00
  AND s.s_market_desc LIKE '%modern%'
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
          AND cr2.cr_return_amount > cr.cr_return_amount
    )
ORDER BY amount_rank, d_ret.d_date, cp.cp_catalog_page_id
LIMIT 100
