WITH page_returns AS (
  SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    t.t_hour,
    t.t_am_pm,
    ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS amt_array,
    CASE WHEN cr.cr_return_amount > 100 THEN 'large' ELSE 'small' END AS amount_category
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE cp.cp_type = 'monthly'
    AND t.t_am_pm = 'PM'
),
page_returns_other AS (
  SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    t.t_hour,
    t.t_am_pm,
    ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS amt_array,
    CASE WHEN cr.cr_return_amount > 100 THEN 'large' ELSE 'small' END AS amount_category
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE cp.cp_type = 'quarterly'
    AND t.t_am_pm = 'AM'
)
SELECT
  pr.cp_catalog_page_id,
  pr.cp_type,
  pr.amount_category,
  unnested_amt AS individual_amount,
  pr.t_hour,
  pr.t_am_pm
FROM (
  SELECT * FROM page_returns
  UNION ALL
  SELECT * FROM page_returns_other
) pr
CROSS JOIN UNNEST(pr.amt_array) AS u(unnested_amt)
ORDER BY pr.cp_catalog_page_id, individual_amount DESC
LIMIT 100
