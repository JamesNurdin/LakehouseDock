WITH
  inventory_agg AS (
    SELECT
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
  ),

  sales_agg AS (
    SELECT
      s.s_state,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(ss.ss_net_paid) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND ib.ib_upper_bound <= 150000
      AND ss.ss_quantity > 0
      AND ss.ss_net_paid IS NOT NULL
    GROUP BY s.s_state, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  ),

  returns_agg AS (
    SELECT
      cc.cc_state,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(DISTINCT cr.cr_order_number) AS return_transactions,
      SUM(COALESCE(i.total_inventory_on_hand, 0)) AS total_inventory_on_hand,
      COUNT(DISTINCT r.r_reason_sk) AS distinct_reason_count
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory_agg i ON w.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND ib.ib_upper_bound <= 150000
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 0
    GROUP BY cc.cc_state, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  ),

  combined AS (
    SELECT
      COALESCE(s.state, r.state) AS state,
      COALESCE(s.income_band_sk, r.income_band_sk) AS income_band_sk,
      COALESCE(s.income_lower, r.income_lower) AS income_lower,
      COALESCE(s.income_upper, r.income_upper) AS income_upper,
      s.total_sales,
      s.sales_transactions,
      r.total_returns,
      r.return_transactions,
      r.total_inventory_on_hand,
      r.distinct_reason_count
    FROM (
      SELECT
        s_state AS state,
        ib_income_band_sk AS income_band_sk,
        ib_lower_bound AS income_lower,
        ib_upper_bound AS income_upper,
        total_sales,
        sales_transactions
      FROM sales_agg
    ) s
    FULL OUTER JOIN (
      SELECT
        cc_state AS state,
        ib_income_band_sk AS income_band_sk,
        ib_lower_bound AS income_lower,
        ib_upper_bound AS income_upper,
        total_returns,
        return_transactions,
        total_inventory_on_hand,
        distinct_reason_count
      FROM returns_agg
    ) r
      ON s.state = r.state
     AND s.income_band_sk = r.income_band_sk
  )

SELECT
  state,
  income_band_sk,
  income_lower,
  income_upper,
  SUM(total_sales) AS total_sales,
  SUM(sales_transactions) AS sales_transactions,
  SUM(total_returns) AS total_returns,
  SUM(return_transactions) AS return_transactions,
  SUM(total_inventory_on_hand) AS total_inventory_on_hand,
  SUM(distinct_reason_count) AS total_distinct_reason_count,
  (SUM(total_sales) - SUM(total_returns)) AS net_sales
FROM combined
GROUP BY GROUPING SETS (
  (state, income_band_sk, income_lower, income_upper),
  (state, income_band_sk),
  (state),
  ()
)
ORDER BY state, income_band_sk NULLS LAST
LIMIT 100
