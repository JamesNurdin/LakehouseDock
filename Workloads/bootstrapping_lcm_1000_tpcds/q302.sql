WITH returns_by_store AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        cd_cr_ret.cd_gender AS cr_returning_gender,
        cd_cr_ref.cd_gender AS cr_refunded_gender,
        cd_wr_ret.cd_gender AS wr_returning_gender,
        cd_wr_ref.cd_gender AS wr_refunded_gender,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_net_loss,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_net_loss,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_return_qty,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_web_return_qty,
        COALESCE(AVG(cr.cr_return_amount), 0) AS avg_catalog_return_amount,
        COALESCE(AVG(wr.wr_return_amt), 0) AS avg_web_return_amount,
        COALESCE(SUM(cr.cr_fee), 0) + COALESCE(SUM(wr.wr_fee), 0) AS total_fees,
        COALESCE(SUM(cr.cr_return_ship_cost), 0) + COALESCE(SUM(wr.wr_return_ship_cost), 0) AS total_ship_cost,
        COALESCE(SUM(cr.cr_reversed_charge), 0) + COALESCE(SUM(wr.wr_reversed_charge), 0) AS total_reversed_charge,
        (COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0)) AS total_net_loss
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd_cr_ret
        ON cr.cr_returning_cdemo_sk = cd_cr_ret.cd_demo_sk
    LEFT JOIN customer_demographics cd_cr_ref
        ON cr.cr_refunded_cdemo_sk = cd_cr_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_ret
        ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_ref
        ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        cd_cr_ret.cd_gender,
        cd_cr_ref.cd_gender,
        cd_wr_ret.cd_gender,
        cd_wr_ref.cd_gender
    HAVING COUNT(DISTINCT cr.cr_order_number) > 0
       OR COUNT(DISTINCT wr.wr_order_number) > 0
)
SELECT
    r.*,
    RANK() OVER (PARTITION BY r.d_year ORDER BY r.total_net_loss DESC) AS store_year_rank
FROM returns_by_store r
ORDER BY r.total_net_loss DESC
LIMIT 100
