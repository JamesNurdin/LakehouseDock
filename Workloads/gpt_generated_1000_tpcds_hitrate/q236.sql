WITH
store_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sr.sr_store_sk AS store_sk,
        CAST(NULL AS varchar) AS web_page_id,
        SUM(sr.sr_net_loss) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_year_loss,
        sr.sr_net_loss AS net_loss,
        LAG(sr.sr_net_loss) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS prev_month_loss
    FROM store_returns sr
    RIGHT OUTER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_fee > 10.00
      AND d.d_moy IN (4, 11)
),
web_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        CAST(NULL AS integer) AS store_sk,
        wp.wp_web_page_id AS web_page_id,
        SUM(wr.wr_net_loss) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_year_loss,
        wr.wr_net_loss AS net_loss,
        LAG(wr.wr_net_loss) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq) AS prev_month_loss
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    RIGHT OUTER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_return_ship_cost > 500.00
      AND d.d_moy IN (4, 11)
)
SELECT *
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
) AS combined
ORDER BY d_year DESC, d_month_seq
LIMIT 100
