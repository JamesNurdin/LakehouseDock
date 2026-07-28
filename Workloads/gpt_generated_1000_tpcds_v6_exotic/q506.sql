WITH joined AS (
  SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    i.i_formulation AS formulation,
    r.r_reason_desc AS reason_desc,
    r.r_reason_id AS reason_id,
    wr.wr_return_amt AS return_amt,
    wr.wr_return_tax AS return_tax,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE i.i_units = 'Box       '
    AND wp.wp_char_count > 500
)
SELECT
  category,
  category_id,
  reason_desc,
  reason_id,
  SUM(return_amt) AS total_return_amount,
  SUM(net_loss) AS total_net_loss
FROM (
  SELECT
    category,
    category_id,
    reason_desc,
    reason_id,
    return_amt,
    net_loss
  FROM joined
  WHERE return_tax >= 30.00

  UNION ALL

  SELECT
    category,
    category_id,
    reason_desc,
    reason_id,
    return_amt,
    net_loss
  FROM joined
  WHERE return_tax < 30.00
    AND formulation LIKE '%olive%'
) AS u
GROUP BY GROUPING SETS (
  (category, category_id, reason_desc, reason_id),
  (category, category_id),
  ()
)
ORDER BY category, reason_desc
