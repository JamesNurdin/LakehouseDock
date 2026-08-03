WITH returns_agg AS (
    SELECT
        s.s_store_id   AS store_id,
        s.s_store_name AS store_name,
        d.d_year       AS year,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss)          AS total_net_loss,
        SUM(cr.cr_return_quantity)   AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
    JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w         ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i         ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret      ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND r.r_reason_desc IN ('Lost my job', 'Gift exchange')
      AND s.s_floor_space > 8000000
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, r.r_reason_desc
)
SELECT
    store_id,
    store_name,
    year,
    reason_desc,
    total_net_loss,
    total_return_qty,
    distinct_orders,
    RANK() OVER (PARTITION BY year ORDER BY total_net_loss DESC) AS loss_rank,
    SUM(total_net_loss) OVER (PARTITION BY store_id ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss_to_year
FROM returns_agg
ORDER BY year, loss_rank
LIMIT 100
