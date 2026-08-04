WITH
    sold_not_returned AS (
        SELECT ss.ss_item_sk
        FROM store_sales ss
        EXCEPT
        SELECT sr.sr_item_sk
        FROM store_returns sr
    ),
    sampled_store_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (5)
    ),
    base AS (
        SELECT
            s.s_store_name,
            d.d_year,
            i.i_brand,
            SUM(ss.ss_net_paid)                         AS total_net_paid,
            SUM(CASE WHEN sr.sr_net_loss > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_loss,
            COUNT(DISTINCT ss.ss_ticket_number)          AS num_transactions,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk                                   -- join 1
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk                                   -- join 2
        JOIN item i ON ss.ss_item_sk = i.i_item_sk                                            -- join 3
        JOIN store s ON ss.ss_store_sk = s.s_store_sk                                         -- join 4
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk                               -- join 5
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk                       -- join 6
        LEFT JOIN sampled_store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number    -- join 7
        LEFT JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
                                 AND ss.ss_sold_date_sk = cr.cr_returned_date_sk   -- join 8
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk               -- join 9
        LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk               -- join10
        LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk                         -- join11
        LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk                           -- join12
        LEFT JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk -- join13 (reuse)
        LEFT JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk -- join14 (reuse)
        LEFT JOIN web_returns wr ON ss.ss_item_sk = wr.wr_item_sk
                                 AND ss.ss_sold_date_sk = wr.wr_returned_date_sk          -- join15
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk                           -- join16
        LEFT JOIN web_site ws ON wp.wp_creation_date_sk = ws.web_open_date_sk                    -- join17
        JOIN date_dim d2 ON ws.web_open_date_sk = d2.d_date_sk                                    -- join18 (second alias of date_dim)
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = ss.ss_item_sk
              AND cr2.cr_returned_date_sk = ss.ss_sold_date_sk
        )
        AND i.i_item_sk IN (SELECT ss_item_sk FROM sold_not_returned)
        GROUP BY
            s.s_store_name,
            d.d_year,
            i.i_brand
        HAVING SUM(ss.ss_net_paid) > 0
    )
SELECT
    s_store_name,
    d_year,
    i_brand,
    total_net_paid,
    total_loss,
    num_transactions,
    rn
FROM base
WHERE rn <= 5
ORDER BY total_net_paid DESC
LIMIT 100
