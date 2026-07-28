WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        w.w_city,
        sm.sm_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_net_paid,
        ws.ws_ext_sales_price
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN tpcds.item i
        ON i.i_item_sk = cr.cr_item_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_returning_cdemo_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = cr.cr_returning_hdemo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND i.i_current_price > 100
      AND w.w_city = 'Spring'
      AND hd.hd_buy_potential = '5001-10000'
      AND cd.cd_gender = 'M'
),
returns_agg AS (
    SELECT
        i_item_id,
        i_item_desc,
        'return' AS activity_type,
        SUM(cr_return_amount) AS amount,
        d_year
    FROM base
    GROUP BY i_item_id, i_item_desc, d_year
),
sales_agg AS (
    SELECT
        i_item_id,
        i_item_desc,
        'sale' AS activity_type,
        SUM(ws_net_paid) AS amount,
        d_year
    FROM base
    GROUP BY i_item_id, i_item_desc, d_year
),
combined AS (
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM sales_agg
)
SELECT
    activity_type,
    i_item_id,
    i_item_desc,
    d_year,
    amount,
    ROW_NUMBER() OVER (PARTITION BY activity_type ORDER BY amount DESC) AS rank_by_amount
FROM combined
ORDER BY activity_type, rank_by_amount
LIMIT 100
