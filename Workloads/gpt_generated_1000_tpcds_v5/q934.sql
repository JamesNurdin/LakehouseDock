WITH return_summary AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_country,
        r.r_reason_sk,
        r.r_reason_desc,
        d.d_date_sk,
        d.d_quarter_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
    WHERE d.d_quarter_name = '1902Q3'
      AND r.r_reason_desc LIKE '%product%'
      AND w.w_country = 'United States'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_country,
        r.r_reason_sk,
        r.r_reason_desc,
        d.d_date_sk,
        d.d_quarter_name
)
SELECT
    rs.w_warehouse_name,
    rs.r_reason_desc,
    rs.d_quarter_name,
    rs.catalog_net_loss,
    rs.store_net_loss,
    (rs.catalog_net_loss + rs.store_net_loss) AS total_net_loss,
    p.p_promo_name,
    ROW_NUMBER() OVER (PARTITION BY rs.w_warehouse_name ORDER BY (rs.catalog_net_loss + rs.store_net_loss) DESC) AS loss_rank,
    CASE
        WHEN (rs.catalog_net_loss + rs.store_net_loss) > (
            SELECT AVG(catalog_net_loss + store_net_loss) FROM return_summary
        ) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS loss_category
FROM return_summary rs
LEFT JOIN promotion p
    ON p.p_start_date_sk = rs.d_date_sk
WHERE (
        p.p_discount_active = 'Y' OR p.p_discount_active IS NULL
    )
ORDER BY total_net_loss DESC
LIMIT 100
