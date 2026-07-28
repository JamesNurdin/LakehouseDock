WITH joined_data AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_order_number,
    wr.wr_return_amt,
    wr.wr_net_loss,
    wr.wr_order_number,
    r_cat.r_reason_desc,
    s.s_store_name,
    s.s_manager,
    ws.web_state,
    dd.d_year,
    dd.d_date
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = dd.d_date_sk
  JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
  JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
  WHERE
    dd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND r_cat.r_reason_desc LIKE '%defect%'
    AND s.s_manager = 'Jerry Brooks'
    AND ws.web_state = 'CA'
    AND cr.cr_return_amount > 100
    AND wr.wr_return_amt > 50
)
SELECT
  s_store_name,
  r_reason_desc,
  SUM(cr_net_loss) AS catalog_net_loss,
  SUM(wr_net_loss) AS web_net_loss,
  SUM(cr_net_loss) + SUM(wr_net_loss) AS total_net_loss,
  RANK() OVER (PARTITION BY s_store_name ORDER BY (SUM(cr_net_loss) + SUM(wr_net_loss)) DESC) AS loss_rank,
  COUNT(DISTINCT cr_order_number) AS catalog_orders,
  COUNT(DISTINCT wr_order_number) AS web_orders
FROM joined_data
GROUP BY s_store_name, r_reason_desc
HAVING (SUM(cr_net_loss) + SUM(wr_net_loss)) > 1000
ORDER BY s_store_name, loss_rank, total_net_loss DESC
LIMIT 100
