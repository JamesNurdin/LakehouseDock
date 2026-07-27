WITH returns_enriched AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_company,
    cc.cc_name,
    dd.d_year,
    i.i_item_id,
    i.i_current_price,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    cd_ref.cd_purchase_estimate,
    CASE
      WHEN wr.wr_net_loss > 1000 THEN 'High'
      WHEN wr.wr_net_loss > 0 THEN 'Medium'
      ELSE 'Low'
    END AS loss_category
  FROM web_returns wr
  JOIN date_dim dd
    ON wr.wr_returned_date_sk = dd.d_date_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN call_center cc
    ON dd.d_date_sk = cc.cc_open_date_sk
  WHERE dd.d_year = 2001
    AND i.i_current_price BETWEEN 20 AND 100
    AND cd_ref.cd_purchase_estimate >= 4000
    AND cc.cc_company = 3
    AND dd.d_month_seq >= 3
)
SELECT
  cc_call_center_id,
  cc_name,
  d_year,
  loss_category,
  SUM(wr_net_loss) AS total_net_loss,
  COUNT(*) AS returns_cnt,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(wr_net_loss) DESC) AS loss_rank
FROM returns_enriched
GROUP BY cc_call_center_id, cc_name, d_year, loss_category
ORDER BY d_year, loss_rank
LIMIT 100
