WITH daily_promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END AS promo_category,
        d.d_year,
        d.d_date,
        t.t_hour,
        sm.sm_type,
        i.i_item_sk,
        i.i_product_name,
        hd.hd_buy_potential,
        cc.cc_name,
        ws.web_site_id,
        wp.wp_web_page_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cr.cr_return_quantity) AS catalog_return_quantity,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(sr.sr_return_quantity) AS store_return_quantity,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(inv_sub.total_inventory) AS total_inventory_on_hand
    FROM store_sales ss
    RIGHT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number IS NOT NULL
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_inventory
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = d.d_date_sk
    ) AS inv_sub
    WHERE d.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END,
        d.d_year,
        d.d_date,
        t.t_hour,
        sm.sm_type,
        i.i_item_sk,
        i.i_product_name,
        hd.hd_buy_potential,
        cc.cc_name,
        ws.web_site_id,
        wp.wp_web_page_id
)
SELECT
    promo_category,
    p_promo_name,
    d_year,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    SUM(store_net_paid) AS total_store_sales,
    SUM(catalog_net_paid) AS total_catalog_sales,
    SUM(catalog_return_loss) AS total_catalog_returns_loss,
    SUM(store_return_amount) AS total_store_returns_amount,
    SUM(total_inventory_on_hand) AS total_inventory_on_hand,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(store_net_paid) DESC) AS sales_rank
FROM daily_promo_sales
GROUP BY promo_category, p_promo_name, d_year
HAVING SUM(store_net_paid) > 100000
ORDER BY total_store_sales DESC
LIMIT 100
