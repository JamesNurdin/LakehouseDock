WITH sales_with_dates AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date_sk,
        d.d_year,
        d.d_moy,
        d.d_date
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1917
      AND d.d_moy = 7
      AND ss.ss_ext_tax > 100
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_net_profit > 0
)
SELECT
    cp.cp_department,
    d_start.d_year,
    d_start.d_moy,
    COUNT(*) AS sales_count,
    SUM(swd.ss_net_paid) AS total_net_paid,
    AVG(swd.ss_ext_tax) AS avg_ext_tax,
    MIN(swd.ss_ext_tax) AS min_ext_tax,
    MAX(swd.ss_ext_tax) AS max_ext_tax,
    (SELECT AVG(ss2.ss_ext_tax) FROM store_sales ss2 WHERE ss2.ss_ext_tax > 500) AS avg_high_tax
FROM sales_with_dates swd
JOIN date_dim d_start
    ON swd.d_date_sk = d_start.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE cp.cp_department = 'Books'
  AND cp.cp_catalog_page_number = 5
  AND d_end.d_year = 1917
  AND d_end.d_moy = 7
  AND cp.cp_type = 'PROMO'
  AND cp.cp_description LIKE '%summer%'
GROUP BY cp.cp_department, d_start.d_year, d_start.d_moy
ORDER BY total_net_paid DESC
LIMIT 100
