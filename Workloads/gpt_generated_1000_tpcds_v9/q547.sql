WITH sub_a AS (
    SELECT
        d_ss.d_date          AS order_date,
        i.i_item_id          AS item_id,
        c.c_customer_id      AS customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit)       AS total_profit
    FROM store_sales ss
    JOIN date_dim d_ss          ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv        ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_date_sk = d_ss.d_date_sk
    JOIN warehouse w           ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr   ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc       ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    GROUP BY d_ss.d_date, i.i_item_id, c.c_customer_id
),
sub_b AS (
    SELECT
        d_ws.d_date          AS order_date,
        i2.i_item_id         AS item_id,
        c2.c_customer_id     AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit)       AS total_profit
    FROM web_sales ws
    JOIN date_dim d_ws          ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i2                ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer c2            ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN inventory inv2        ON inv2.inv_item_sk = i2.i_item_sk
                               AND inv2.inv_date_sk = d_ws.d_date_sk
    JOIN warehouse w2           ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
    JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we            ON ws.ws_web_site_sk = we.web_site_sk
    GROUP BY d_ws.d_date, i2.i_item_id, c2.c_customer_id
)
SELECT
    order_date,
    item_id,
    customer_id,
    SUM(total_sales) AS agg_sales,
    SUM(total_profit) AS agg_profit,
    CASE WHEN SUM(total_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
FROM (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
) u
GROUP BY order_date, item_id, customer_id
ORDER BY agg_sales DESC
LIMIT 100
