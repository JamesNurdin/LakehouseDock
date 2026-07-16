SELECT
  agg.d_year,
  agg.d_month_seq,
  agg.r_reason_desc,
  agg.s_city,
  agg.num_returns,
  agg.total_net_loss,
  agg.avg_return_tax,
  agg.total_images,
  agg.avg_char_count,
  ROW_NUMBER() OVER (PARTITION BY agg.s_city ORDER BY agg.total_net_loss DESC) AS city_loss_rank
FROM (
    SELECT
      d.d_year,
      d.d_month_seq,
      r.r_reason_desc,
      s.s_city,
      COUNT(cr.cr_order_number) AS num_returns,
      SUM(cr.cr_net_loss) AS total_net_loss,
      AVG(cr.cr_return_tax) AS avg_return_tax,
      SUM(wp.wp_image_count) AS total_images,
      AVG(wp.wp_char_count) AS avg_char_count
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
      AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
      d.d_year,
      d.d_month_seq,
      r.r_reason_desc,
      s.s_city
    HAVING COUNT(cr.cr_order_number) > 10
) agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
