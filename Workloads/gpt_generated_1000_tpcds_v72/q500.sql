WITH filtered_returns AS (
   SELECT
     sr.sr_store_sk,
     sr.sr_item_sk,
     sr.sr_cdemo_sk,
     sr.sr_reason_sk,
     d.d_date_sk,
     d.d_year,
     i.i_category,
     r.r_reason_desc,
     sr.sr_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_category = 'Sports'
     AND r.r_reason_desc LIKE '%color%'
),
catalog_sales_join AS (
   SELECT
     cs.cs_item_sk,
     cs.cs_sold_date_sk,
     cs.cs_ext_sales_price,
     cs.cs_call_center_sk,
     cs.cs_warehouse_sk,
     cs.cs_net_profit
   FROM catalog_sales cs
)
SELECT
  ws.s_store_name,
  ws.s_state,
  fr.d_year,
  SUM(fr.sr_net_loss)                              AS total_store_return_loss,
  SUM(cs.cs_ext_sales_price)                       AS total_catalog_sales_amount,
  SUM(cr.cr_net_loss)                              AS total_catalog_return_loss,
  SUM(wr.wr_net_loss)                              AS total_web_return_loss,
  CASE WHEN SUM(fr.sr_net_loss) > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_indicator,
  RANK() OVER (PARTITION BY fr.d_year ORDER BY SUM(fr.sr_net_loss) DESC) AS loss_rank
FROM filtered_returns fr
JOIN catalog_sales_join cs
  ON cs.cs_item_sk = fr.sr_item_sk
 AND cs.cs_sold_date_sk = fr.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store ws
  ON fr.sr_store_sk = ws.s_store_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = fr.d_date_sk
 AND cr.cr_item_sk = fr.sr_item_sk
 AND cr.cr_reason_sk = fr.sr_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = fr.d_date_sk
 AND wr.wr_item_sk = fr.sr_item_sk
 AND wr.wr_reason_sk = fr.sr_reason_sk
WHERE EXISTS (
   SELECT 1
   FROM web_site we
   WHERE we.web_company_name = 'pri'
     AND we.web_open_date_sk = fr.d_date_sk
)
GROUP BY ws.s_store_name, ws.s_state, fr.d_year
ORDER BY fr.d_year, loss_rank
LIMIT 100
