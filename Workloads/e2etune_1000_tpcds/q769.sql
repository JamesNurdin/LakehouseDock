WITH aggregated AS (
  SELECT
    cr.cr_returning_customer_sk AS customer_sk,
    wp.wp_type,
    SUM(cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
    SUM(cr.cr_refunded_cash + sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_return_quantity + sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    CASE WHEN SUM(cr.cr_net_loss + sr.sr_net_loss) = 0 THEN NULL
         ELSE SUM(cr.cr_refunded_cash + sr.sr_refunded_cash) / SUM(cr.cr_net_loss + sr.sr_net_loss)
    END AS refund_to_loss_ratio
  FROM catalog_returns cr
  JOIN store_returns sr
    ON cr.cr_returning_customer_sk = sr.sr_customer_sk
    AND cr.cr_item_sk = sr.sr_item_sk
    AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = cr.cr_returning_customer_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450926 AND 2451065
    AND cr.cr_fee > 30
    AND sr.sr_return_amt_inc_tax > 0
  GROUP BY cr.cr_returning_customer_sk, wp.wp_type
  HAVING SUM(cr.cr_return_quantity + sr.sr_return_quantity) >= 5
)
SELECT
  customer_sk,
  wp_type,
  total_net_loss,
  total_refunded_cash,
  total_return_quantity,
  catalog_orders,
  store_tickets,
  refund_to_loss_ratio,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 10
