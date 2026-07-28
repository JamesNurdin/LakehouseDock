WITH aggregated_returns AS (
  SELECT
    d.d_year,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS cat_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS cat_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    ROW_NUMBER() OVER (
      PARTITION BY d.d_year
      ORDER BY (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) DESC
    ) AS loss_rank
  FROM
    date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
    LEFT JOIN household_demographics hd_cr_ref ON hd_cr_ref.hd_demo_sk = cr.cr_refunded_hdemo_sk
    LEFT JOIN household_demographics hd_cr_ret ON hd_cr_ret.hd_demo_sk = cr.cr_returning_hdemo_sk
    LEFT JOIN household_demographics hd_sr ON hd_sr.hd_demo_sk = sr.sr_hdemo_sk
    LEFT JOIN household_demographics hd_wr_ref ON hd_wr_ref.hd_demo_sk = wr.wr_refunded_hdemo_sk
  WHERE
    d.d_year BETWEEN 1999 AND 2002
    AND r.r_reason_desc IS NOT NULL
    AND cr.cr_return_quantity > 0
    AND sr.sr_return_quantity > 0
    AND wr.wr_return_quantity > 0
    AND cr.cr_return_amount > 0
    AND wr.wr_web_page_sk IN (
      SELECT DISTINCT wp.wp_web_page_sk
      FROM web_page wp
      WHERE wp.wp_image_count >= 2
        AND wp.wp_type = 'product'
    )
  GROUP BY
    d.d_year,
    r.r_reason_desc
)
SELECT
  ar.d_year,
  ar.r_reason_desc,
  ar.cat_net_loss,
  ar.store_net_loss,
  ar.web_net_loss,
  ar.loss_rank
FROM
  aggregated_returns ar
WHERE
  ar.loss_rank <= 5
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN reason r2 ON r2.r_reason_sk = cr2.cr_reason_sk
    WHERE cr2.cr_net_loss > 1000
      AND r2.r_reason_desc = ar.r_reason_desc
  )
ORDER BY
  ar.d_year,
  ar.loss_rank
LIMIT 100
