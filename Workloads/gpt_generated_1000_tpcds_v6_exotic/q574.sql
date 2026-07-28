WITH base AS (
    SELECT
        ws.ws_order_number            AS order_number,
        d.d_year                      AS d_year,
        ws.ws_ext_sales_price         AS sales,
        ws.ws_net_profit              AS net_profit,
        p.p_promo_id                  AS p_promo_id,
        p.p_discount_active           AS p_discount_active,
        site.web_name                 AS web_name,
        w.w_state                     AS w_state,
        cc.cc_city                    AS cc_city,
        cd.cd_gender                  AS cd_gender,
        wp.wp_type                    AS wp_type,
        cr.cr_return_amount           AS cr_return_amount,
        inv.inv_quantity_on_hand      AS inv_quantity_on_hand,
        sr.sr_return_amt              AS sr_return_amt,
        wr.wr_return_amt              AS wr_return_amt
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_returns cr
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
       AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
       AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND site.web_manager = 'James Austin'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cc.cc_city = 'Seattle'
      AND wp.wp_type = 'Home'
),
agg1 AS (
    SELECT
        web_name,
        p_promo_id,
        d_year,
        SUM(sales)               AS total_sales,
        AVG(net_profit)          AS avg_profit,
        COUNT(DISTINCT order_number) AS orders_cnt,
        SUM(cr_return_amount)    AS total_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory,
        SUM(sr_return_amt)       AS total_store_return,
        SUM(wr_return_amt)       AS total_web_return
    FROM base
    GROUP BY web_name, p_promo_id, d_year
)
SELECT
    web_name,
    d_year,
    SUM(total_sales)          AS site_sales,
    AVG(avg_profit)           AS site_avg_profit,
    SUM(orders_cnt)           AS site_orders,
    SUM(total_return_amount)  AS site_return_amount,
    SUM(total_inventory)      AS site_inventory
FROM agg1
GROUP BY web_name, d_year
HAVING SUM(total_sales) > 100000
ORDER BY site_sales DESC
LIMIT 100
