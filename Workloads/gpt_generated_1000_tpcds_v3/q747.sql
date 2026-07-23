WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_paid) AS ws_total_net_paid,
        SUM(ws.ws_quantity) AS ws_total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_ship_mode_sk, ws.ws_promo_sk
),
sales_agg AS (
    SELECT
        p_sale.p_promo_name      AS p_promo_name,
        sm_sale.sm_type          AS ship_mode_type,
        w_sale.w_warehouse_name  AS w_warehouse_name,
        SUM(cs.cs_net_paid)      AS total_catalog_net_paid,
        SUM(ws_agg.ws_total_net_paid) AS total_web_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_net_paid) + SUM(ws_agg.ws_total_net_paid) AS total_combined_net_paid
    FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm_sale ON cs.cs_ship_mode_sk = sm_sale.sm_ship_mode_sk
        JOIN warehouse w_sale ON cs.cs_warehouse_sk = w_sale.w_warehouse_sk
        JOIN promotion p_sale ON cs.cs_promo_sk = p_sale.p_promo_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
        JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
        JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
        JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
        JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN inventory inv ON inv.inv_warehouse_sk = w_sale.w_warehouse_sk
        JOIN ws_agg ON ws_agg.ws_warehouse_sk = w_sale.w_warehouse_sk
                     AND ws_agg.ws_ship_mode_sk = sm_sale.sm_ship_mode_sk
                     AND ws_agg.ws_promo_sk = p_sale.p_promo_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_cdemo_sk = cd_bill.cd_demo_sk
          AND sr.sr_return_quantity > 0
    )
    GROUP BY p_sale.p_promo_name, sm_sale.sm_type, w_sale.w_warehouse_name
)
SELECT
    p_promo_name,
    ship_mode_type,
    w_warehouse_name,
    total_catalog_net_paid,
    total_web_net_paid,
    distinct_orders,
    total_combined_net_paid,
    ROW_NUMBER() OVER (ORDER BY total_combined_net_paid DESC) AS revenue_rank
FROM sales_agg
ORDER BY total_combined_net_paid DESC
LIMIT 100
