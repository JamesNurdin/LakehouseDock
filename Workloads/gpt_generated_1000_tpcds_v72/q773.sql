-- Goal: Analyze yearly profit by customer gender and item category across store sales, web sales, and their returns, using deep joins across all TPC‑DS tables, an anti‑join filter, and a ranking window function.
WITH aggregated AS (
    SELECT
        d_sold.d_year AS year,
        cd.cd_gender AS gender,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(wr.wr_net_loss) AS total_web_returns_loss
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    -- Store returns (joined via ticket number and return date/time)
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk

    -- Web sales (different customer and demographics aliases)
    JOIN web_sales ws ON ws.ws_item_sk = ss.ss_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk

    -- Web returns (joined via order number and return date/time)
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN customer c_wr ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
    JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

    -- Catalog returns (joined via item and various dimensions)
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer c_cr ON cr.cr_refunded_customer_sk = c_cr.c_customer_sk
    JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
    JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk

    -- Anti‑join: exclude catalog pages that have a lower‑numbered page in the same catalog
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_id = cp.cp_catalog_page_id
          AND cp2.cp_catalog_number < cp.cp_catalog_number
    )
    GROUP BY d_sold.d_year, cd.cd_gender, i.i_category
)
SELECT
    a.year,
    a.gender,
    a.category,
    a.total_store_profit,
    a.total_web_profit,
    a.total_store_returns_loss,
    a.total_web_returns_loss,
    RANK() OVER (PARTITION BY a.year ORDER BY (a.total_store_profit + a.total_web_profit) DESC) AS profit_rank
FROM aggregated a
ORDER BY a.total_store_profit DESC
LIMIT 100
