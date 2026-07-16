WITH aggregated AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_week_seq,
        s.s_store_id,
        s.s_city,
        s.s_gmt_offset,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_catalog_return_tax,
        AVG(wr.wr_return_tax) AS avg_web_return_tax,
        SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        CASE
            WHEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) = 0 THEN 0
            ELSE SUM(cr.cr_return_amount) / (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt))
        END AS catalog_return_ratio
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'TX'
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_week_seq,
        s.s_store_id,
        s.s_city,
        s.s_gmt_offset
    HAVING SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) > 1000
)
SELECT
    a.d_date,
    a.d_year,
    a.d_week_seq,
    a.s_store_id,
    a.s_city,
    a.s_gmt_offset,
    a.total_catalog_return_amount,
    a.total_web_return_amount,
    a.total_return_amount,
    a.avg_catalog_return_tax,
    a.avg_web_return_tax,
    a.total_return_quantity,
    a.total_net_loss,
    a.catalog_return_ratio,
    ROW_NUMBER() OVER (ORDER BY a.total_return_amount DESC) AS return_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
