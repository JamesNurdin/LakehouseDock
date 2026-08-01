WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        r.r_reason_desc,
        sm_cs.sm_type AS ship_mode_type,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit
    FROM catalog_sales cs
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN time_dim td_ret
        ON cr.cr_returned_time_sk = td_ret.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
),
agg AS (
    SELECT
        b.i_item_id,
        b.i_product_name,
        b.i_category,
        b.cp_catalog_number,
        b.cp_catalog_page_number,
        b.r_reason_desc,
        b.ship_mode_type,
        b.cs_item_sk,
        SUM(b.cs_quantity) AS total_catalog_quantity,
        SUM(b.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(b.cs_net_profit) AS total_catalog_profit,
        SUM(b.cr_return_quantity) AS total_return_quantity,
        SUM(b.cr_return_amount) AS total_return_amount,
        SUM(b.cr_net_loss) AS total_return_loss,
        SUM(b.ws_quantity) AS total_web_quantity,
        SUM(b.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(b.ws_net_profit) AS total_web_profit,
        (SELECT AVG(cs2.cs_net_profit)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = b.cs_item_sk) AS avg_item_catalog_profit
    FROM base b
    GROUP BY
        b.i_item_id,
        b.i_product_name,
        b.i_category,
        b.cp_catalog_number,
        b.cp_catalog_page_number,
        b.r_reason_desc,
        b.ship_mode_type,
        b.cs_item_sk
    HAVING
        SUM(b.cs_net_paid_inc_tax) > 1000
)
SELECT
    a.*,
    ROW_NUMBER() OVER (ORDER BY a.total_catalog_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.total_catalog_sales DESC, sales_rank
