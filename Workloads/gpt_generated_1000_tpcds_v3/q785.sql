WITH base_data AS (
  SELECT
    ss.ss_sold_date_sk,
    d_s.d_date,
    d_s.d_year,
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_profit,
    ss.ss_sales_price,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_purchase_estimate,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_state AS customer_state,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cp.cp_department,
    cp.cp_type,
    inv.inv_quantity_on_hand,
    CASE
      WHEN ss.ss_net_profit > 1500 THEN 'High'
      WHEN ss.ss_net_profit BETWEEN 500 AND 1500 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category
  FROM
    store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_s.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_s.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  WHERE
    d_s.d_year = 2001
    AND cd.cd_credit_rating = 'Good'
    AND ib.ib_lower_bound >= 50000
    AND cd.cd_purchase_estimate >= 5000
), agg_data AS (
  SELECT
    d_date,
    d_year,
    ss_store_sk,
    profit_category,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(inv_quantity_on_hand) AS total_inventory_on_day
  FROM base_data
  WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE d_wp.d_date = base_data.d_date
      AND wp.wp_type = 'Content'
  )
  GROUP BY
    d_date,
    d_year,
    ss_store_sk,
    profit_category
)
SELECT
  d_date,
  ss_store_sk,
  profit_category,
  total_quantity_sold,
  total_net_profit,
  total_inventory_on_day,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_by_year
FROM agg_data
ORDER BY profit_rank_by_year, total_net_profit DESC
LIMIT 100
