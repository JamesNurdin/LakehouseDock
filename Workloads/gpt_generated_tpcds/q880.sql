WITH store_monthly AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
catalog_monthly AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
promo_monthly AS (
    SELECT d_month.d_year,
           d_month.d_month_seq,
           SUM(p.p_cost) AS promo_cost
    FROM promotion p
    JOIN date_dim d_start
      ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
      ON p.p_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_month
      ON d_month.d_date BETWEEN d_start.d_date AND d_end.d_date
    WHERE d_month.d_year = 2001
    GROUP BY d_month.d_year, d_month.d_month_seq
),
combined AS (
    SELECT COALESCE(s.d_year, c.d_year, w.d_year, p.d_year) AS year,
           COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq, p.d_month_seq) AS month_seq,
           COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
           COALESCE(p.promo_cost, 0) AS total_promo_cost
    FROM store_monthly s
    FULL OUTER JOIN catalog_monthly c
      ON s.d_year = c.d_year AND s.d_month_seq = c.d_month_seq
    FULL OUTER JOIN web_monthly w
      ON COALESCE(s.d_year, c.d_year) = w.d_year AND COALESCE(s.d_month_seq, c.d_month_seq) = w.d_month_seq
    FULL OUTER JOIN promo_monthly p
      ON COALESCE(s.d_year, c.d_year, w.d_year) = p.d_year AND COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq) = p.d_month_seq
)
SELECT year,
       month_seq,
       total_net_loss,
       total_promo_cost,
       CASE WHEN total_promo_cost = 0 THEN NULL ELSE total_net_loss / total_promo_cost END AS loss_to_promo_ratio
FROM combined
ORDER BY year, month_seq
