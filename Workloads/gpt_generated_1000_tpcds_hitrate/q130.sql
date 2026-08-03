WITH returns_summary AS (
  SELECT
    d_ret.d_year AS year,
    d_ret.d_month_seq AS month_seq,
    p.p_promo_name AS promo_name,
    ca_ref.ca_state AS state,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_return_quantity) AS sum_return_qty,
    COUNT(*) AS cnt_returns
  FROM catalog_returns cr
  JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
  JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
  WHERE d_ret.d_year = 2002
    AND d_ret.d_month_seq BETWEEN 1200 AND 1300
    AND t.t_hour BETWEEN 9 AND 17
    AND ca_ref.ca_state IN ('CA', 'TX')
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand > 0
  GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    p.p_promo_name,
    ca_ref.ca_state
)

SELECT
  year,
  promo_name,
  AVG(sum_return_amount) AS avg_return_amount,
  SUM(cnt_returns) AS total_returns
FROM returns_summary
GROUP BY GROUPING SETS (
    (year, promo_name),
    (year),
    ()
)
HAVING AVG(sum_return_amount) > 500
ORDER BY avg_return_amount DESC, year DESC
LIMIT 100
