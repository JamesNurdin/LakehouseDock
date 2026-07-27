WITH sales_data AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_promo_sk) AS promo_count,
        (
            SELECT SUM(i.inv_quantity_on_hand)
            FROM inventory i
            WHERE i.inv_date_sk = d.d_date_sk
        ) AS inventory_qty,
        MAX(p.p_channel_email) AS any_email_channel,
        MAX(cd.cd_gender) AS gender,
        MAX(hd.hd_buy_potential) AS buy_potential
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_date_sk, d.d_date, d.d_year, ss.ss_store_sk, ss.ss_item_sk
)
SELECT
    sd.d_date,
    sd.d_year,
    sd.total_sales,
    sd.total_profit,
    sd.total_quantity,
    sd.inventory_qty,
    sd.promo_count,
    sd.any_email_channel,
    sd.gender,
    sd.buy_potential,
    w.w_warehouse_name,
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    r.r_reason_desc,
    wp.wp_url,
    ws.web_name AS website_name
FROM sales_data sd
JOIN date_dim d2 ON sd.d_date_sk = d2.d_date_sk
JOIN (
    SELECT i.inv_date_sk, i.inv_warehouse_sk
    FROM inventory i
    GROUP BY i.inv_date_sk, i.inv_warehouse_sk
) inv ON inv.inv_date_sk = d2.d_date_sk
JOIN warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d2.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d2.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d2.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d2.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d2.d_date_sk
WHERE sd.d_year = 2001
  AND sd.total_quantity > 100
  AND w.w_city = 'Washington'
ORDER BY sd.total_profit DESC
LIMIT 100
