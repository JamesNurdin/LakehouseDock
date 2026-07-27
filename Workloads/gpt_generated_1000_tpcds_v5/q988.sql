WITH joined_data AS (
  SELECT
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_fee,
    cr.cr_order_number,
    d_ret.d_year,
    d_ret.d_month_seq,
    t.t_meal_time,
    i.i_brand,
    i.i_category,
    ca.ca_state,
    cd_ref.cd_credit_rating,
    s.s_market_desc
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
  WHERE d_ret.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND ca.ca_state = 'TX'
    AND cd_ref.cd_credit_rating = 'Good'
    AND t.t_meal_time = 'dinner'
    AND s.s_market_desc LIKE '%Local%'
),
agg_data AS (
  SELECT
    i_brand,
    i_category,
    ca_state,
    cd_credit_rating,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_fee) AS avg_fee,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MIN(cr_return_quantity) AS min_quantity,
    MAX(cr_return_tax) AS max_tax,
    SUM(CASE WHEN cd_credit_rating = 'Good' THEN cr_return_amount ELSE 0 END) AS good_credit_return_amount
  FROM joined_data
  GROUP BY i_brand, i_category, ca_state, cd_credit_rating
)
SELECT
  i_brand,
  i_category,
  ca_state,
  cd_credit_rating,
  total_return_amount,
  avg_fee,
  distinct_orders,
  min_quantity,
  max_tax,
  good_credit_return_amount,
  SUM(total_return_amount) OVER (PARTITION BY i_brand ORDER BY total_return_amount DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_brand_return
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 100
