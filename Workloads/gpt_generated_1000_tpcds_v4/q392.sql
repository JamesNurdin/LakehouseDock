/* goal: calculate total sales and returns by item and promotion across catalog, store, and web channels, and classify profit level */
WITH
    /* Base fact: catalog sales joined to its dimensions */
    catalog_base AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cs.cs_order_number,
            cs.cs_bill_customer_sk,
            cs.cs_ship_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_ship_mode_sk,
            cs.cs_promo_sk
        FROM tpcds.catalog_sales cs
    ),
    /* Join all other tables directly to the catalog base (star topology) */
    joined_all AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            p.p_promo_name,
            c_bill.c_customer_id   AS bill_customer_id,
            c_ship.c_customer_id   AS ship_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state,
            sm.sm_type,
            cs.cs_net_paid,
            cs.cs_net_profit,
            ss.ss_net_paid               AS store_net_paid,
            ws.ws_net_paid               AS web_net_paid,
            wr.wr_return_amt             AS return_amount,
            r.r_reason_desc,
            inv.inv_quantity_on_hand,
            wp.wp_url
        FROM catalog_base cs
        /* item */
        INNER JOIN tpcds.item i
            ON cs.cs_item_sk = i.i_item_sk
        /* promotion */
        INNER JOIN tpcds.promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        /* billing customer */
        INNER JOIN tpcds.customer c_bill
            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        /* shipping customer (second alias of customer) */
        INNER JOIN tpcds.customer c_ship
            ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        /* customer demographics (using billing demo) */
        INNER JOIN tpcds.customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        /* household demographics (using billing hdemo) */
        INNER JOIN tpcds.household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        /* income band for the household */
        INNER JOIN tpcds.income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        /* billing address */
        INNER JOIN tpcds.customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        /* ship mode */
        INNER JOIN tpcds.ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        /* store sales (joined via the same item) */
        LEFT JOIN tpcds.store_sales ss
            ON ss.ss_item_sk = i.i_item_sk
        /* store dimension (via store_sales) */
        LEFT JOIN tpcds.store s
            ON ss.ss_store_sk = s.s_store_sk
        /* inventory (same item) */
        LEFT JOIN tpcds.inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        /* web sales (same item) */
        LEFT JOIN tpcds.web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
        /* web page (via web_sales) */
        LEFT JOIN tpcds.web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        /* web returns (via order number and item) */
        LEFT JOIN tpcds.web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = i.i_item_sk
        /* reason for return */
        LEFT JOIN tpcds.reason r
            ON wr.wr_reason_sk = r.r_reason_sk
    )
SELECT
    i_item_id,
    i_product_name,
    p_promo_name,
    COUNT(DISTINCT bill_customer_id)                         AS distinct_bill_customers,
    SUM(cs_net_paid)                                          AS total_catalog_sales,
    SUM(COALESCE(store_net_paid, 0))                         AS total_store_sales,
    SUM(COALESCE(web_net_paid, 0))                           AS total_web_sales,
    SUM(COALESCE(return_amount, 0))                         AS total_returns,
    SUM(cs_net_profit)                                        AS total_catalog_profit,
    CASE
        WHEN SUM(cs_net_profit) > 10000 THEN 'High'
        WHEN SUM(cs_net_profit) > 0    THEN 'Medium'
        ELSE 'Low'
    END                                                      AS profit_category,
    MIN(ib_lower_bound)                                      AS income_band_low,
    MAX(ib_upper_bound)                                      AS income_band_high,
    COUNT(DISTINCT r_reason_desc)                            AS distinct_return_reasons,
    SUM(inv_quantity_on_hand)                                AS total_inventory_on_hand
FROM joined_all
GROUP BY
    i_item_id,
    i_product_name,
    p_promo_name
ORDER BY total_catalog_sales DESC
LIMIT 100
