WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_net_paid,
    ss.ss_quantity,
    i.i_item_id,
    i.i_current_price,
    cd.cd_gender,
    w.w_state,
    w.w_warehouse_id,
    w.w_zip,
    ca.ca_city,
    hd.hd_buy_potential,
    c.c_customer_id,
    inv.inv_quantity_on_hand
  FROM store_sales ss
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  RIGHT OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
  WHERE NOT EXISTS (
        SELECT 1 FROM inventory inv_check
        WHERE inv_check.inv_item_sk = ss.ss_item_sk
          AND inv_check.inv_warehouse_sk = w.w_warehouse_sk
      )
      AND i.i_current_price > (SELECT MAX(i_current_price) FROM item) / 2
),
aggregated AS (
  SELECT
    w_state,
    w_warehouse_id,
    CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    COUNT(*) AS sales_cnt
  FROM base
  GROUP BY w_state, w_warehouse_id, cd_gender
),
ranked AS (
  SELECT
    w_state,
    w_warehouse_id,
    gender_desc,
    total_net_paid,
    unique_customers,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_net_paid DESC) AS rnk,
    CASE
      WHEN total_net_paid > 100000 THEN 'High'
      WHEN total_net_paid > 50000 THEN 'Medium'
      ELSE 'Low'
    END AS revenue_category
  FROM aggregated
)
SELECT
  w_state,
  w_warehouse_id,
  gender_desc,
  total_net_paid,
  unique_customers,
  revenue_category
FROM ranked
WHERE rnk <= 5
ORDER BY w_state, total_net_paid DESC
LIMIT 100
