WITH q1 AS (
  SELECT
    cc.cc_company_name,
    cc.cc_city,
    r.r_reason_desc,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_loss
  FROM call_center cc
  JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
  WHERE cc.cc_company_name = 'ese'
    AND cr.cr_return_quantity > 1
    AND cr.cr_return_amount > 100
    AND cr.cr_order_number IN (23, 31)
    AND cr.cr_returned_date_sk = 20220101
    AND r.r_reason_desc LIKE '%Remarkable%'
  GROUP BY cc.cc_company_name, cc.cc_city, r.r_reason_desc
),
q2 AS (
  SELECT
    cc.cc_company_name,
    cc.cc_city,
    r.r_reason_desc,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_loss
  FROM call_center cc
  JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
  WHERE cc.cc_company_name = 'pri'
    AND cr.cr_return_quantity <= 3
    AND cr.cr_return_amount < 500
    AND cr.cr_order_number IN (16, 35)
    AND cr.cr_returned_date_sk = 20220202
    AND r.r_reason_desc LIKE '%Dangerous%'
  GROUP BY cc.cc_company_name, cc.cc_city, r.r_reason_desc
),
unioned AS (
  SELECT * FROM q1
  UNION
  SELECT * FROM q2
),
final AS (
  SELECT
    cc_company_name,
    cc_city,
    r_reason_desc,
    total_loss,
    ROW_NUMBER() OVER (PARTITION BY cc_company_name ORDER BY total_loss DESC) AS loss_rank,
    CASE
      WHEN total_loss > (SELECT AVG(total_loss) FROM unioned) THEN 'HIGH'
      ELSE 'LOW'
    END AS loss_category
  FROM unioned
)
SELECT *
FROM final
ORDER BY cc_company_name, loss_rank
