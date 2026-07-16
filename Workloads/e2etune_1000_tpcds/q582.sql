WITH filtered_returns AS (
  SELECT
    cr.cr_refunded_addr_sk,
    cr.cr_returning_addr_sk,
    cr.cr_net_loss,
    cr.cr_return_amount,
    cr.cr_return_amt_inc_tax,
    cr.cr_return_quantity,
    CASE
      WHEN cr.cr_net_loss > 1000 THEN 'High'
      WHEN cr.cr_net_loss BETWEEN 500 AND 1000 THEN 'Medium'
      ELSE 'Low'
    END AS loss_category
  FROM catalog_returns cr
  WHERE cr.cr_ship_mode_sk IN (2, 13)
    AND cr.cr_return_tax > 30
    AND cr.cr_return_amt_inc_tax >= 500
)
SELECT
  ca_refunded.ca_state AS refunded_state,
  ca_refunded.ca_city AS refunded_city,
  fr.loss_category,
  COUNT(*) AS num_returns,
  SUM(fr.cr_net_loss) AS total_net_loss,
  SUM(fr.cr_return_amount) AS total_return_amount,
  AVG(fr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
  RANK() OVER (PARTITION BY fr.loss_category ORDER BY SUM(fr.cr_net_loss) DESC) AS loss_category_rank
FROM filtered_returns fr
JOIN customer_address ca_refunded
  ON fr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON fr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE ca_refunded.ca_country = 'United States'
  AND ca_returning.ca_state = ca_refunded.ca_state
GROUP BY ca_refunded.ca_state, ca_refunded.ca_city, fr.loss_category
HAVING COUNT(*) >= 5
ORDER BY fr.loss_category, total_net_loss DESC
LIMIT 100
