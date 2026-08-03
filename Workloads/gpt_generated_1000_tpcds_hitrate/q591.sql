WITH sales_returns AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_ext_sales_price,
       sr.sr_return_amt_inc_tax,
       td.t_shift AS sales_shift,
       td.t_sub_shift,
       td.t_second,
       regexp_extract(td.t_sub_shift, '(mor|aft|eve|night)', 1) AS sub_shift_code,
       CASE
           WHEN regexp_like(td.t_shift, '^morning') THEN 'MORN'
           WHEN regexp_like(td.t_shift, '^afternoon') THEN 'AFT'
           ELSE 'OTHER'
       END AS shift_group,
       concat(CAST(ss.ss_ticket_number AS varchar), '-', CAST(sr.sr_ticket_number AS varchar)) AS ticket_pair
   FROM store_sales ss
   JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
   JOIN time_dim td
       ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE ss.ss_ext_sales_price > 1000
     AND td.t_shift LIKE 'morning%'
)
SELECT
   shift_group,
   sub_shift_code,
   sales_shift,
   af.t_shift AS af_shift,
   SUM(ss_ext_sales_price) AS total_sales,
   SUM(sr_return_amt_inc_tax) AS total_return,
   COUNT(*) AS txn_count,
   (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns) AS avg_return_amt
FROM sales_returns
CROSS JOIN (SELECT DISTINCT t_shift FROM time_dim WHERE t_shift LIKE 'afternoon%') af
GROUP BY CUBE (shift_group, sub_shift_code, sales_shift, af.t_shift)
ORDER BY total_sales DESC
LIMIT 100
