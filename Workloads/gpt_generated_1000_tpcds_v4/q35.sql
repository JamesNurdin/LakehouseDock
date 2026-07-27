WITH store_ret AS (
   SELECT d.d_date AS return_date,
          'store' AS source,
          SUM(sr.sr_return_amt) AS total_return_amount,
          SUM(sr.sr_net_loss) AS total_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
     AND s.s_market_id IN (SELECT DISTINCT s2.s_market_id FROM store s2 WHERE s2.s_state = 'CA')
   GROUP BY d.d_date
),
catalog_ret AS (
   SELECT d.d_date AS return_date,
          'catalog' AS source,
          SUM(cr.cr_return_amount) AS total_return_amount,
          SUM(cr.cr_net_loss) AS total_net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
     AND cp.cp_department = 'Books'
     AND EXISTS (SELECT 1 FROM store s3 WHERE s3.s_market_id = 5 AND s3.s_state = 'CA')
   GROUP BY d.d_date
)
SELECT return_date,
       source,
       total_return_amount,
       total_net_loss
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) AS combined
ORDER BY return_date, total_net_loss DESC
LIMIT 100
