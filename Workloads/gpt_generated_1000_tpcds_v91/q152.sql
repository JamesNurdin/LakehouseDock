/* Goal: Analyze item performance by combining sales, returns, inventory, promotions and demographic information, focusing on items sold both in physical stores and online, and rank them by total net paid amount. */
WITH inv_agg AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_brand
),
store_sales_agg AS (
    SELECT ss.ss_item_sk      AS item_sk,
           ss.ss_sold_time_sk AS time_sk,
           ss.ss_store_sk     AS store_sk,
           ss.ss_promo_sk    AS promo_sk,
           ss.ss_cdemo_sk    AS cd_sk,
           SUM(ss.ss_net_paid)       AS store_net_paid,
           SUM(ss.ss_quantity)       AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_time_sk, ss.ss_store_sk, ss.ss_promo_sk, ss.ss_cdemo_sk
),
catalog_sales_agg AS (
    SELECT cs.cs_item_sk      AS item_sk,
           cs.cs_sold_time_sk AS time_sk,
           cs.cs_ship_mode_sk AS ship_mode_sk,
           cs.cs_promo_sk    AS promo_sk,
           cs.cs_bill_cdemo_sk AS cd_sk,
           SUM(cs.cs_net_paid)       AS catalog_net_paid,
           SUM(cs.cs_quantity)       AS catalog_qty
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_time_sk, cs.cs_ship_mode_sk, cs.cs_promo_sk, cs.cs_bill_cdemo_sk
),
web_sales_agg AS (
    SELECT ws.ws_item_sk      AS item_sk,
           ws.ws_sold_time_sk AS time_sk,
           ws.ws_ship_mode_sk AS ship_mode_sk,
           ws.ws_promo_sk    AS promo_sk,
           ws.ws_bill_cdemo_sk AS cd_sk,
           ws.ws_web_page_sk AS web_page_sk,
           SUM(ws.ws_net_paid)       AS web_net_paid,
           SUM(ws.ws_quantity)       AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_sold_time_sk, ws.ws_ship_mode_sk, ws.ws_promo_sk, ws.ws_bill_cdemo_sk, ws.ws_web_page_sk
),
catalog_returns_agg AS (
    SELECT cr.cr_item_sk      AS item_sk,
           cr.cr_returned_time_sk AS time_sk,
           cr.cr_ship_mode_sk AS ship_mode_sk,
           SUM(cr.cr_return_amount)   AS catalog_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_time_sk, cr.cr_ship_mode_sk
),
web_returns_agg AS (
    SELECT wr.wr_item_sk      AS item_sk,
           wr.wr_returned_time_sk AS time_sk,
           wr.wr_web_page_sk AS web_page_sk,
           SUM(wr.wr_return_amt)      AS web_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_returned_time_sk, wr.wr_web_page_sk
),
sales_union AS (
    SELECT item_sk,
           time_sk,
           ship_mode_sk,
           promo_sk,
           cd_sk,
           NULL               AS web_page_sk,
           catalog_net_paid   AS net_paid,
           catalog_qty        AS qty
    FROM catalog_sales_agg
    UNION ALL
    SELECT item_sk,
           time_sk,
           ship_mode_sk,
           promo_sk,
           cd_sk,
           web_page_sk,
           web_net_paid       AS net_paid,
           web_qty            AS qty
    FROM web_sales_agg
),
intersect_items AS (
    SELECT DISTINCT ss.item_sk
    FROM store_sales_agg ss
    INTERSECT
    SELECT DISTINCT ws.item_sk
    FROM web_sales_agg ws
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    inv.total_inventory,
    SUM(COALESCE(su.net_paid, 0))               AS total_net_paid,
    SUM(COALESCE(su.qty, 0))                   AS total_quantity,
    SUM(COALESCE(cr_agg.catalog_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_agg.web_return_amount, 0))    AS total_web_returns,
    SUM(COALESCE(ss.store_net_paid, 0))          AS total_store_net_paid,
    SUM(COALESCE(ss.store_qty, 0))               AS total_store_qty,
    pr.p_promo_name,
    sm.sm_type,
    cd.cd_gender,
    t.t_hour,
    st.s_store_name,
    wp.wp_url,
    i2.i_manufact AS item_manufacturer,
    pr2.p_promo_name AS item_promo_name
FROM inv_agg inv
JOIN intersect_items ii ON inv.i_item_sk = ii.item_sk
JOIN item i ON inv.i_item_sk = i.i_item_sk
LEFT JOIN sales_union su ON i.i_item_sk = su.item_sk
LEFT JOIN store_sales_agg ss ON i.i_item_sk = ss.item_sk
LEFT JOIN store st ON ss.store_sk = st.s_store_sk
LEFT JOIN promotion pr ON su.promo_sk = pr.p_promo_sk
LEFT JOIN ship_mode sm ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer_demographics cd ON su.cd_sk = cd.cd_demo_sk
LEFT JOIN time_dim t ON su.time_sk = t.t_time_sk
LEFT JOIN web_page wp ON su.web_page_sk = wp.wp_web_page_sk
LEFT JOIN catalog_returns_agg cr_agg ON i.i_item_sk = cr_agg.item_sk
LEFT JOIN ship_mode sm_cr ON cr_agg.ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN web_returns_agg wr_agg ON i.i_item_sk = wr_agg.item_sk
LEFT JOIN item i2 ON cr_agg.item_sk = i2.i_item_sk
LEFT JOIN promotion pr2 ON i2.i_item_sk = pr2.p_item_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    inv.total_inventory,
    pr.p_promo_name,
    sm.sm_type,
    cd.cd_gender,
    t.t_hour,
    st.s_store_name,
    wp.wp_url,
    i2.i_manufact,
    pr2.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
