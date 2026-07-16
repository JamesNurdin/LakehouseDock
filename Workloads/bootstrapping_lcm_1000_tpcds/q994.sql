SELECT
    department,
    catalog_year,
    store_name,
    store_city,
    warehouse_name,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    return_cnt,
    RANK() OVER (PARTITION BY department ORDER BY total_net_loss DESC) AS loss_rank_by_department
FROM (
    SELECT
        cp.cp_department AS department,
        dp.d_year AS catalog_year,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        w.w_warehouse_name AS warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = dr.d_date_sk
    JOIN date_dim dp
        ON cp.cp_end_date_sk = dp.d_date_sk
    WHERE dp.d_year BETWEEN 2010 AND 2020
      AND dr.d_year = 2022
    GROUP BY
        cp.cp_department,
        dp.d_year,
        s.s_store_name,
        s.s_city,
        w.w_warehouse_name
) t
ORDER BY total_net_loss DESC
LIMIT 100
