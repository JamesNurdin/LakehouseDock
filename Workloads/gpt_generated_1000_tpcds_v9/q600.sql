WITH store_agg AS (
    SELECT
        cd.cd_gender AS gender,
        i.i_brand AS brand,
        d.d_year AS sale_year,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS return_amount,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_cnt,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws_site
        ON ws_site.web_open_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_closed_date_sk = d.d_date_sk
          AND cc2.cc_company_name = 'Company A'
    )
    GROUP BY GROUPING SETS (
        (cd.cd_gender, i.i_brand, d.d_year),
        (cd.cd_gender, i.i_brand),
        (cd.cd_gender),
        ()
    )
),

web_agg AS (
    SELECT
        cd2.cd_gender AS gender,
        i2.i_brand AS brand,
        d2.d_year AS sale_year,
        SUM(ws.ws_net_paid) AS sales_amount,
        0.0 AS return_amount,
        SUM(COALESCE(inv2.inv_quantity_on_hand, 0)) AS inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS transaction_cnt,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d2
        ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN item i2
        ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer_demographics cd2
        ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN promotion p2
        ON ws.ws_promo_sk = p2.p_promo_sk
    LEFT JOIN inventory inv2
        ON inv2.inv_item_sk = i2.i_item_sk
        AND inv2.inv_date_sk = d2.d_date_sk
    LEFT JOIN warehouse w2
        ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN web_page wp2
        ON ws.ws_web_page_sk = wp2.wp_web_page_sk
    LEFT JOIN web_site web2
        ON ws.ws_web_site_sk = web2.web_site_sk
    LEFT JOIN call_center cc2
        ON cc2.cc_open_date_sk = d2.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_desc = 'Other'
    )
    GROUP BY GROUPING SETS (
        (cd2.cd_gender, i2.i_brand, d2.d_year),
        (cd2.cd_gender, i2.i_brand),
        (cd2.cd_gender),
        ()
    )
),

combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)

SELECT
    gender,
    brand,
    sale_year,
    channel,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    SUM(inventory_qty) AS total_inventory,
    SUM(transaction_cnt) AS total_transactions
FROM combined
GROUP BY GROUPING SETS (
    (gender, brand, sale_year, channel),
    (gender, brand, channel),
    (gender, channel),
    (channel)
)
ORDER BY total_sales DESC
LIMIT 100
