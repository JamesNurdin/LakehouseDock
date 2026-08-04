WITH
    ss_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_date_sk,
            SUM(ss_net_paid) AS total_net_paid,
            SUM(ss_quantity) AS total_quantity
        FROM store_sales
        WHERE ss_sales_price > 0
        GROUP BY ss_store_sk, ss_sold_date_sk
    ),
    sr_agg AS (
        SELECT
            sr_store_sk,
            sr_returned_date_sk,
            SUM(sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM store_returns
        WHERE sr_return_amt > 0
        GROUP BY sr_store_sk, sr_returned_date_sk
    ),
    cs_agg AS (
        SELECT
            cs_catalog_page_sk,
            cs_sold_date_sk,
            cs_bill_customer_sk,
            SUM(cs_net_paid) AS cat_total_net_paid,
            SUM(cs_quantity) AS cat_total_qty
        FROM catalog_sales
        WHERE cs_sales_price > 0
        GROUP BY cs_catalog_page_sk, cs_sold_date_sk, cs_bill_customer_sk
    ),
    diff_keys AS (
        SELECT ss_store_sk AS store_sk, ss_sold_date_sk AS date_sk
        FROM store_sales
        EXCEPT
        SELECT sr_store_sk, sr_returned_date_sk
        FROM store_returns
    )
SELECT
    d.d_year,
    s.s_store_name,
    cp.cp_department,
    CASE WHEN cp.cp_type = 'TRAVEL' THEN 'Travel Dept' ELSE 'Other Dept' END AS dept_category,
    ss_agg.total_net_paid,
    COALESCE(sr_agg.total_return_amt, 0) AS total_return_amt,
    cs_agg.cat_total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.total_net_paid DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY (ss_agg.total_net_paid - COALESCE(sr_agg.total_return_amt, 0)) DESC) AS net_profit_rank
FROM ss_agg
JOIN diff_keys dk
  ON ss_agg.ss_store_sk = dk.store_sk
 AND ss_agg.ss_sold_date_sk = dk.date_sk
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN cs_agg
  ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
  ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN sr_agg
  ON sr_agg.sr_store_sk = s.s_store_sk
 AND sr_agg.sr_returned_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND cp.cp_department = 'Books'
  AND hd.hd_income_band_sk = 5
  AND r.r_reason_desc = 'Damaged'
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_number = cp.cp_catalog_number
          AND cp2.cp_catalog_page_number > 10
      )
ORDER BY net_profit_rank ASC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
