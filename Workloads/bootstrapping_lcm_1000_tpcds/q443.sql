WITH returns_by_store_website AS (
  SELECT
    s.s_store_id,
    s.s_city AS store_city,
    ws.web_site_id,
    ws.web_name AS website_name,
    d.d_year,
    d.d_quarter_name,
    d.d_weekend,
    CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_net_loss) AS sum_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    MAX(cr.cr_fee) AS max_fee,
    MIN(cr.cr_return_tax) AS min_return_tax
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN web_site ws
    ON (ws.web_open_date_sk = d.d_date_sk OR ws.web_close_date_sk = d.d_date_sk)
  WHERE d.d_year BETWEEN 2000 AND 2005
    AND s.s_state = 'CA'
    AND ws.web_state = 'CA'
  GROUP BY
    s.s_store_id,
    s.s_city,
    ws.web_site_id,
    ws.web_name,
    d.d_year,
    d.d_quarter_name,
    d.d_weekend
)
SELECT
  rbsw.s_store_id,
  rbsw.store_city,
  rbsw.web_site_id,
  rbsw.website_name,
  rbsw.d_year,
  rbsw.d_quarter_name,
  rbsw.day_type,
  rbsw.total_returns,
  rbsw.sum_return_amount,
  rbsw.sum_net_loss,
  rbsw.avg_return_qty,
  rbsw.max_fee,
  rbsw.min_return_tax,
  ROW_NUMBER() OVER (PARTITION BY rbsw.s_store_id ORDER BY rbsw.sum_net_loss DESC) AS net_loss_rank_by_store,
  RANK() OVER (PARTITION BY rbsw.d_year ORDER BY rbsw.sum_return_amount DESC) AS return_amount_rank_by_year
FROM returns_by_store_website rbsw
WHERE rbsw.total_returns > 10
ORDER BY rbsw.sum_net_loss DESC
LIMIT 100
