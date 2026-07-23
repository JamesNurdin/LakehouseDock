WITH
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM store_sales ss
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales ws
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt
    FROM catalog_sales cs
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    GROUP BY
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    GROUP BY
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_reason_sk
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand
    FROM inventory inv
    GROUP BY
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    i.i_category,
    p.p_promo_name,
    i.i_item_sk,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.store_sales_amount) AS total_store_sales,
    SUM(ws.web_sales_amount) AS total_web_sales,
    SUM(cs.catalog_sales_amount) AS total_catalog_sales,
    SUM(cr.catalog_return_amount) AS total_catalog_returns,
    SUM(wr.web_return_amount) AS total_web_returns,
    SUM(inv.inventory_on_hand) AS total_inventory_on_hand,
    (SUM(ss.store_profit) + SUM(ws.web_profit) + SUM(cs.catalog_profit)) AS total_profit,
    (SELECT MAX(p2.p_discount_active) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_discount_active
FROM store_sales_agg ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_sales_agg ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
JOIN catalog_sales_agg cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns_agg cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
JOIN web_returns_agg wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
JOIN inventory_agg inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND cd.cd_credit_rating = 'Good'
    AND inv.inventory_on_hand > 100
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM reason r_exists
        WHERE r_exists.r_reason_sk = cr.cr_reason_sk
          AND r_exists.r_reason_desc = 'Damaged'
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    i.i_category,
    p.p_promo_name,
    i.i_item_sk
ORDER BY total_store_sales DESC
LIMIT 100
