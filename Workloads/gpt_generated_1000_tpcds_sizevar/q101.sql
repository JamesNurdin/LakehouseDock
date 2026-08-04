WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        ss.ss_ext_list_price,
        cr.cr_net_loss,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        sm.sm_carrier,
        ws.ws_net_paid_inc_tax,
        cd.cd_gender,
        ca.ca_state,
        ws.ws_ext_sales_price,
        web_site.web_name
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND i.i_current_price > 100
      AND inv.inv_quantity_on_hand > 0
      AND ss.ss_net_paid_inc_tax > 500
      AND ws.ws_net_paid_inc_tax > 300
      AND ca.ca_state = 'CA'
),
with_discount AS (
    SELECT
        b.*,
        ld.store_discount_ratio
    FROM base b
    CROSS JOIN LATERAL (
        SELECT CASE WHEN b.ss_ext_list_price = 0 THEN 0
                    ELSE b.ss_ext_discount_amt / b.ss_ext_list_price
               END AS store_discount_ratio
    ) ld
)
SELECT
    wd.i_category,
    wd.sm_carrier,
    wd.cd_gender,
    SUM(wd.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(wd.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(wd.cr_net_loss) + SUM(wd.wr_net_loss) AS total_loss,
    AVG(wd.inv_quantity_on_hand) AS avg_inventory,
    AVG(wd.store_discount_ratio) AS avg_store_discount,
    (SUM(wd.ss_net_paid_inc_tax) + SUM(wd.ws_net_paid_inc_tax) - (SUM(wd.cr_net_loss) + SUM(wd.wr_net_loss)))
        / NULLIF((SUM(wd.ss_net_paid_inc_tax) + SUM(wd.ws_net_paid_inc_tax)), 0) AS profit_margin
FROM with_discount wd
GROUP BY wd.i_category, wd.sm_carrier, wd.cd_gender
HAVING SUM(wd.ss_net_paid_inc_tax) > 1000
ORDER BY profit_margin DESC
LIMIT 100
