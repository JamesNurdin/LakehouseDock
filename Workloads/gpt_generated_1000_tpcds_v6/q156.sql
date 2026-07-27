WITH agg_sales AS (
    SELECT cs_catalog_page_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_catalog_page_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    agg.total_sales,
    agg.total_profit,
    cr.cr_return_amount,
    CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'NonPositive' END AS return_amount_flag,
    r.r_reason_desc,
    sr.sr_refunded_cash,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY agg.total_sales DESC) AS dept_sales_rank
FROM agg_sales AS agg
JOIN catalog_page cp
  ON agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE cp.cp_department = 'Electronics'
  AND cr.cr_store_credit > 100.00
  AND sr.sr_refunded_cash < 500.00
  AND r.r_reason_desc LIKE '%Damaged%'
  AND cr.cr_returning_customer_sk IN (2173169, 8836584)
LIMIT 100
