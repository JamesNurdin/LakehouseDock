WITH item_colors AS (
  SELECT i_item_sk,
         array_agg(i_color) AS colors
  FROM item
  GROUP BY i_item_sk
),
filtered_customers AS (
  SELECT c_customer_sk,
         c_first_name,
         c_last_name,
         c_preferred_cust_flag
  FROM customer
  WHERE c_customer_sk IN (
        SELECT DISTINCT wr_refunded_customer_sk
        FROM web_returns
        WHERE wr_return_amt > 200
      )
)
SELECT
  wr.wr_returned_date_sk,
  cust.c_customer_sk,
  cust.c_first_name,
  cust.c_last_name,
  dem.cd_gender,
  itm.i_item_id,
  itm.i_current_price,
  inv.inv_quantity_on_hand,
  rsn.r_reason_desc,
  SUM(wr.wr_return_amt) AS total_return_amount,
  AVG(wr.wr_return_quantity) AS avg_return_qty,
  COUNT(*) AS return_cnt,
  MIN(wr.wr_return_amt) AS min_return_amt,
  MAX(wr.wr_return_amt) AS max_return_amt,
  col_expanded.color AS item_color
FROM web_returns wr
JOIN filtered_customers cust
  ON wr.wr_refunded_customer_sk = cust.c_customer_sk
JOIN customer_demographics dem
  ON wr.wr_refunded_cdemo_sk = dem.cd_demo_sk
JOIN item itm
  ON wr.wr_item_sk = itm.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = itm.i_item_sk
JOIN reason rsn
  ON wr.wr_reason_sk = rsn.r_reason_sk
JOIN item_colors ic
  ON ic.i_item_sk = itm.i_item_sk
CROSS JOIN LATERAL (
    SELECT color
    FROM UNNEST(ic.colors) AS t(color)
) AS col_expanded
WHERE
  cust.c_preferred_cust_flag = 'Y'
  AND dem.cd_purchase_estimate >= 4000
  AND inv.inv_quantity_on_hand < 800
  AND itm.i_current_price BETWEEN 20 AND 100
  AND rsn.r_reason_desc LIKE '%defect%'
GROUP BY
  wr.wr_returned_date_sk,
  cust.c_customer_sk,
  cust.c_first_name,
  cust.c_last_name,
  dem.cd_gender,
  itm.i_item_id,
  itm.i_current_price,
  inv.inv_quantity_on_hand,
  rsn.r_reason_desc,
  col_expanded.color
ORDER BY total_return_amount DESC
LIMIT 100
