WITH base AS (
    SELECT
        td.t_shift,
        cd.cd_credit_rating,
        ss.ss_net_paid_inc_tax AS store_sales_inc_tax,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_net_loss AS web_net_loss,
        ss.ss_item_sk AS store_item_sk,
        cr.cr_item_sk AS catalog_item_sk,
        wr.wr_item_sk AS web_item_sk
    FROM time_dim td
    FULL OUTER JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    WHERE td.t_shift IN ('first', 'second', 'third')
      AND (ss.ss_quantity > 0 OR ss.ss_quantity IS NULL)
      AND (cr.cr_return_quantity > 0 OR cr.cr_return_quantity IS NULL)
)
SELECT
    b.t_shift,
    b.cd_credit_rating,
    SUM(COALESCE(b.store_sales_inc_tax, 0)) AS total_store_sales,
    SUM(COALESCE(b.catalog_net_loss, 0)) AS total_catalog_loss,
    SUM(COALESCE(b.web_net_loss, 0)) AS total_web_loss,
    SUM(COALESCE(b.store_sales_inc_tax, 0) + COALESCE(b.catalog_net_loss, 0) + COALESCE(b.web_net_loss, 0)) AS total_combined_loss,
    RANK() OVER (PARTITION BY b.t_shift
                 ORDER BY SUM(COALESCE(b.store_sales_inc_tax, 0) + COALESCE(b.catalog_net_loss, 0) + COALESCE(b.web_net_loss, 0)) DESC) AS loss_rank
FROM base b
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = b.store_item_sk
          AND wr2.wr_return_amt_inc_tax > 5000
      )
  AND b.t_shift <> (SELECT MIN(t_shift) FROM time_dim WHERE t_shift IS NOT NULL)
GROUP BY ROLLUP (b.t_shift, b.cd_credit_rating)
HAVING SUM(COALESCE(b.store_sales_inc_tax, 0) + COALESCE(b.catalog_net_loss, 0) + COALESCE(b.web_net_loss, 0)) > 5000
ORDER BY b.t_shift NULLS LAST, loss_rank
LIMIT 100
