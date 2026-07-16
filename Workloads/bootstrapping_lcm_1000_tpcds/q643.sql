WITH aggregated_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND t.t_hour BETWEEN 6 AND 22
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    ar.s_store_id,
    ar.s_store_name,
    ar.d_year,
    ar.t_hour,
    ar.w_warehouse_name,
    ar.total_net_loss,
    ar.return_cnt,
    ar.total_net_loss / ar.return_cnt AS avg_net_loss_per_return,
    ROW_NUMBER() OVER (PARTITION BY ar.d_year ORDER BY ar.total_net_loss DESC) AS loss_rank_year
FROM aggregated_returns ar
ORDER BY ar.d_year, loss_rank_year
LIMIT 200
