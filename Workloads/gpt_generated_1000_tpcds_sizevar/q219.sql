WITH
  catalog_agg AS (
    SELECT
      cr.cr_reason_sk AS reason_sk,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt,
      AVG(cr.cr_net_loss) AS avg_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 17
      AND ca_ret.ca_state = 'CA'
      AND hd_ret.hd_income_band_sk > 5
      AND cr.cr_return_quantity > 5
    GROUP BY cr.cr_reason_sk
  ),
  web_agg AS (
    SELECT
      wr.wr_reason_sk AS reason_sk,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt,
      AVG(wr.wr_net_loss) AS avg_net_loss
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
    JOIN household_demographics hd_ret2 ON wr.wr_returning_hdemo_sk = hd_ret2.hd_demo_sk
    JOIN customer_address ca_ret2 ON wr.wr_returning_addr_sk = ca_ret2.ca_address_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d3 ON wp.wp_creation_date_sk = d3.d_date_sk
    WHERE d2.d_year = 2001
      AND t2.t_hour BETWEEN 8 AND 17
      AND ca_ret2.ca_state = 'CA'
      AND hd_ret2.hd_income_band_sk > 5
      AND wr.wr_return_quantity > 5
    GROUP BY wr.wr_reason_sk
  ),
  common_reasons AS (
    SELECT reason_sk FROM catalog_agg
    INTERSECT
    SELECT reason_sk FROM web_agg
  )
SELECT
  r.r_reason_id,
  r.r_reason_desc,
  ca.total_net_loss AS catalog_total_loss,
  wa.total_net_loss AS web_total_loss,
  (ca.total_net_loss + wa.total_net_loss) / (ca.cnt + wa.cnt) AS combined_avg_loss
FROM common_reasons cr
JOIN catalog_agg ca ON cr.reason_sk = ca.reason_sk
JOIN web_agg wa ON cr.reason_sk = wa.reason_sk
JOIN reason r ON cr.reason_sk = r.r_reason_sk
ORDER BY combined_avg_loss DESC
LIMIT 100
