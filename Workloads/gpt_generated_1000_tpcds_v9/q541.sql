WITH return_summary AS (
  SELECT
    s.s_store_id,
    s.s_state,
    i.i_category,
    i.i_category_id,
    cp.cp_department,
    dd.d_year,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount_per_return,
    inv_agg.total_on_hand
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON i.i_item_sk = p.p_item_sk
  JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
  CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = dd.d_date_sk
  ) AS inv_agg
  WHERE i.i_category_id IN (1, 4, 9)
    AND dd.d_year = 2020
    AND ib.ib_upper_bound >= 150000
    AND p.p_discount_active = 'Y'
  GROUP BY
    s.s_store_id,
    s.s_state,
    i.i_category,
    i.i_category_id,
    cp.cp_department,
    dd.d_year,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv_agg.total_on_hand
),
state_summary AS (
  SELECT
    s_state,
    AVG(total_return_amount) AS avg_return_amount_state,
    SUM(total_return_amount) AS sum_return_amount_state,
    COUNT(*) AS store_count
  FROM return_summary
  GROUP BY s_state
  HAVING SUM(total_return_amount) > 5000
)
SELECT
  rs.s_store_id,
  rs.s_state,
  rs.i_category,
  rs.i_category_id,
  rs.cp_department,
  rs.total_return_amount,
  rs.distinct_customers,
  rs.avg_return_amount_per_return,
  rs.total_on_hand,
  ss.avg_return_amount_state,
  ROW_NUMBER() OVER (PARTITION BY rs.s_state ORDER BY rs.total_return_amount DESC) AS rn_state_rank
FROM return_summary rs
JOIN state_summary ss ON rs.s_state = ss.s_state
WHERE rs.total_return_amount > 1000
ORDER BY rs.total_return_amount DESC
LIMIT 100
