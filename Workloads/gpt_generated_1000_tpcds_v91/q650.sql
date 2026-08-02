(
  SELECT DISTINCT cs.cs_item_sk AS item_sk
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cr.cr_net_loss > 0
    AND cc.cc_division = 3
    AND cc.cc_rec_start_date >= DATE '2000-01-01'
)
INTERSECT
(
  SELECT DISTINCT wr.wr_item_sk AS item_sk
  FROM web_returns wr
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE wr.wr_net_loss > 0
    AND cd.cd_gender = 'F'
    AND i.i_current_price > 20
)
LIMIT 100
