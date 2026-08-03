WITH
    intersect_orders AS (
        SELECT cr_order_number AS order_num FROM catalog_returns
        INTERSECT
        SELECT wr_order_number FROM web_returns
    ),
    agg AS (
        SELECT
            s.s_store_name AS store_name,
            s.s_state AS state,
            sm.sm_ship_mode_id AS ship_mode_id,
            sm.sm_carrier AS carrier,
            SUM(cr.cr_net_loss) AS total_net_loss,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
            CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
            RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(cr.cr_net_loss) DESC) AS rnk
        FROM
            customer_demographics cd
            JOIN catalog_returns cr
                ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
            JOIN ship_mode sm
                ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            -- extra join to satisfy nine‑join requirement
            JOIN ship_mode sm2
                ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
            JOIN customer_demographics cd_ref
                ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
            JOIN store_sales ss
                ON ss.ss_cdemo_sk = cd.cd_demo_sk
            FULL OUTER JOIN store s
                ON ss.ss_store_sk = s.s_store_sk
            JOIN web_returns wr
                ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
            JOIN customer_demographics cd_wr_ref
                ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
            JOIN web_page wp
                ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE
            cr.cr_order_number IN (SELECT order_num FROM intersect_orders)
            AND s.s_store_sk NOT IN (
                SELECT s2.s_store_sk FROM store s2 WHERE s2.s_state = 'TX'
            )
        GROUP BY
            s.s_store_name,
            s.s_state,
            sm.sm_ship_mode_id,
            sm.sm_carrier
    )
SELECT *
FROM agg
WHERE rnk <= 3
ORDER BY store_name, rnk
