WITH agg AS (
    SELECT
        s.s_store_id,
        cc.cc_call_center_id,
        i.i_category,
        d_sold.d_date AS sales_date,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS return_loss,
        CASE
            WHEN (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) > 50000 THEN 'High'
            ELSE 'Low'
        END AS profit_level,
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) AS total_profit
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN date_dim d_returned
        ON sr.sr_returned_date_sk = d_returned.d_date_sk
    LEFT JOIN time_dim t_returned
        ON sr.sr_return_time_sk = t_returned.t_time_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_cr_returned
        ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
    LEFT JOIN time_dim t_cr_returned
        ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
    LEFT JOIN reason r2
        ON cr.cr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    GROUP BY
        s.s_store_id,
        cc.cc_call_center_id,
        i.i_category,
        d_sold.d_date
    HAVING
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) > 10000
)
SELECT
    agg.s_store_id,
    agg.cc_call_center_id,
    agg.i_category,
    agg.sales_date,
    agg.store_profit,
    agg.catalog_profit,
    agg.return_loss,
    agg.profit_level,
    agg.total_profit,
    SUM(agg.total_profit) OVER (PARTITION BY agg.s_store_id ORDER BY agg.sales_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM agg
ORDER BY agg.total_profit DESC
LIMIT 100
