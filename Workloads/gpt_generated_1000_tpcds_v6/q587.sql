WITH combined AS (
  /* Store channel – includes optional Web return data */
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    i.i_item_id,
    i.i_category,
    i.i_category_id,
    s.s_store_id,
    s.s_state,
    c.c_customer_id,
    cr.cr_net_loss,
    sr.sr_return_amt               AS return_amount,
    sr.sr_return_quantity          AS return_quantity,
    sr.sr_net_loss                 AS net_loss_detail
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                        AND sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE s.s_number_employees > 200                      -- predicate 1
    AND i.i_category_id IN (1, 6, 9)                    -- predicate 2
    AND s.s_state = 'TX'                               -- predicate 3
    AND cr.cr_return_amount > 100                      -- predicate 4
    AND sr.sr_return_ship_cost > 0                     -- predicate 5

  UNION ALL

  /* Web channel – includes optional Store return data */
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    i.i_item_id,
    i.i_category,
    i.i_category_id,
    s.s_store_id,
    s.s_state,
    c.c_customer_id,
    cr.cr_net_loss,
    wr.wr_return_amt               AS return_amount,
    wr.wr_return_quantity          AS return_quantity,
    wr.wr_net_loss                 AS net_loss_detail
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE i.i_category_id = 8                               -- predicate 6
    AND cr.cr_return_amount BETWEEN 50 AND 500          -- predicate 7
    AND wr.wr_return_quantity >= 2                      -- predicate 8
    AND wr.wr_return_ship_cost > 0                      -- predicate 9
    AND c.c_birth_country = 'United States'            -- predicate 10
)
SELECT
  combined.cr_returned_date_sk,
  combined.i_item_id,
  combined.i_category,
  combined.i_category_id,
  combined.c_customer_id,
  combined.cr_return_amount,
  combined.cr_return_quantity,
  combined.s_store_id,
  combined.s_state,
  combined.cr_net_loss,
  combined.return_amount,
  combined.return_quantity,
  combined.net_loss_detail,
  ROW_NUMBER() OVER (PARTITION BY combined.i_category_id ORDER BY combined.cr_return_amount DESC) AS rn_category,
  CASE WHEN combined.cr_net_loss > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_flag
FROM combined
ORDER BY combined.i_category_id, rn_category
LIMIT 100
