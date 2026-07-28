WITH base AS (
    SELECT
        ds.d_year,
        cc.cc_name,
        wp.wp_type,
        ib.ib_income_band_sk,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_net_loss AS web_net_loss
    FROM
        catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN date_dim ds
            ON cs.cs_sold_date_sk = ds.d_date_sk
        JOIN time_dim ts
            ON cs.cs_sold_time_sk = ts.t_time_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN web_sales ws
            ON cs.cs_order_number = ws.ws_order_number
            AND cs.cs_item_sk = ws.ws_item_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
        JOIN inventory inv
            ON inv.inv_date_sk = ds.d_date_sk
        -- additional date_dim joins to satisfy the join rules for call_center and web_page
        JOIN date_dim d_closed
            ON cc.cc_closed_date_sk = d_closed.d_date_sk
        JOIN date_dim d_open
            ON cc.cc_open_date_sk = d_open.d_date_sk
        JOIN date_dim d_wp_creation
            ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        JOIN date_dim d_wp_access
            ON wp.wp_access_date_sk = d_wp_access.d_date_sk
),
agg AS (
    SELECT
        d_year,
        cc_name,
        wp_type,
        ib_income_band_sk,
        SUM(catalog_net_profit) AS total_catalog_profit,
        SUM(web_net_profit) AS total_web_profit,
        SUM(catalog_net_loss) AS total_catalog_loss,
        SUM(web_net_loss) AS total_web_loss,
        SUM(catalog_net_profit + web_net_profit - catalog_net_loss - web_net_loss) AS net_margin
    FROM base
    WHERE d_year BETWEEN 2000 AND 2002
      AND hd_vehicle_count > 1
      AND ib_upper_bound <= 120000
    GROUP BY ROLLUP (cc_name, wp_type, ib_income_band_sk, d_year)
    HAVING SUM(catalog_net_profit + web_net_profit) > 0
)
SELECT
    ib_income_band_sk,
    d_year,
    AVG(net_margin) AS avg_net_margin,
    SUM(total_catalog_profit) AS sum_catalog_profit,
    SUM(total_web_profit) AS sum_web_profit
FROM agg
GROUP BY CUBE (ib_income_band_sk, d_year)
ORDER BY ib_income_band_sk, d_year
