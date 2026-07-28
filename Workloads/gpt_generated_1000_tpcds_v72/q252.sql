WITH filtered_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cr.cr_net_loss AS cr_net_loss,
        i.i_item_desc,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '(?i)promo')
      AND cd.cd_gender = 'F'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = cr.cr_item_sk
            AND wr.wr_returned_date_sk = cr.cr_returned_date_sk
      )
)
SELECT
    year_month,
    d_year,
    d_month_seq,
    total_net_loss,
    avg_net_loss,
    return_cnt,
    rank_by_year
FROM (
    SELECT
        CONCAT(CAST(d_year AS VARCHAR), '-', LPAD(CAST(d_month_seq AS VARCHAR), 2, '0')) AS year_month,
        d_year,
        d_month_seq,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(cr_net_loss) DESC) AS rank_by_year
    FROM filtered_returns
    GROUP BY d_year, d_month_seq
    HAVING SUM(cr_net_loss) > 1000
) AS agg
ORDER BY d_year DESC, total_net_loss DESC
LIMIT 100
