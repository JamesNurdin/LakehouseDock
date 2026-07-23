WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_brand_id,
        i.i_category,
        i.i_product_name,
        p.p_discount_active,
        sm.sm_type,
        cp.cp_department,
        cs.cs_net_profit AS catalog_net_profit,
        cs.cs_net_paid AS catalog_net_paid,
        cr.cr_net_loss AS catalog_return_net_loss,
        ss.ss_net_profit AS store_net_profit,
        ss.ss_net_paid AS store_net_paid,
        sr.sr_net_loss AS store_return_net_loss,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_net_paid AS web_net_paid,
        wr.wr_net_loss AS web_return_net_loss,
        r.r_reason_desc,
        ca.ca_state,
        hd.hd_income_band_sk,
        wsite.web_name,
        wsite.web_state
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r
        ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
),
item_agg AS (
    SELECT
        i_item_sk,
        i_brand_id,
        i_category,
        i_product_name,
        p_discount_active,
        sm_type,
        cp_department,
        SUM(catalog_net_profit) AS sum_catalog_profit,
        SUM(store_net_profit) AS sum_store_profit,
        SUM(web_net_profit) AS sum_web_profit,
        SUM(catalog_return_net_loss) AS sum_catalog_return_loss,
        SUM(store_return_net_loss) AS sum_store_return_loss,
        SUM(web_return_net_loss) AS sum_web_return_loss,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY
        i_item_sk,
        i_brand_id,
        i_category,
        i_product_name,
        p_discount_active,
        sm_type,
        cp_department
)
SELECT
    ia.i_brand_id,
    ia.i_category,
    ia.sm_type,
    ia.p_discount_active,
    SUM(ia.sum_catalog_profit) AS total_catalog_profit,
    SUM(ia.sum_store_profit) AS total_store_profit,
    SUM(ia.sum_web_profit) AS total_web_profit,
    SUM(ia.sum_catalog_return_loss) AS total_catalog_return_loss,
    SUM(ia.sum_store_return_loss) AS total_store_return_loss,
    SUM(ia.sum_web_return_loss) AS total_web_return_loss,
    (SUM(ia.sum_catalog_profit) + SUM(ia.sum_store_profit) + SUM(ia.sum_web_profit)) AS total_net_profit,
    COUNT(DISTINCT ia.i_item_sk) AS distinct_items,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_count
FROM item_agg ia
WHERE
    ia.i_brand_id IN (8007005, 6016006)
    AND ia.sm_type = 'OVERNIGHT'
    AND ia.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ia.i_item_sk
          AND sr2.sr_net_loss > 500
    )
GROUP BY
    ia.i_brand_id,
    ia.i_category,
    ia.sm_type,
    ia.p_discount_active
HAVING
    (SUM(ia.sum_catalog_profit) + SUM(ia.sum_store_profit) + SUM(ia.sum_web_profit)) > 50000
ORDER BY
    total_net_profit DESC
LIMIT 100
