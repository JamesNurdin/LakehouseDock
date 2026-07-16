WITH returns_combined AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_quantity,
        'catalog' AS source
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        r.r_reason_desc AS reason_desc,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_quantity,
        'web' AS source
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    d_date,
    d_year,
    s_store_name,
    s_city,
    s_state,
    reason_desc,
    source,
    total_return_amount,
    total_net_loss,
    total_return_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS year_rank
FROM (
    SELECT
        d_date,
        d_year,
        s_store_name,
        s_city,
        s_state,
        reason_desc,
        source,
        SUM(return_amount) AS total_return_amount,
        SUM(net_loss) AS total_net_loss,
        SUM(return_quantity) AS total_return_quantity
    FROM returns_combined
    WHERE d_year BETWEEN 2000 AND 2002
    GROUP BY
        d_date,
        d_year,
        s_store_name,
        s_city,
        s_state,
        reason_desc,
        source
) agg
ORDER BY year_rank, d_date DESC
LIMIT 100
