WITH aggregated AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        sm.sm_ship_mode_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        store_sales ss
        RIGHT OUTER JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN ship_mode sm
            ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
        LEFT JOIN customer_demographics cd
            ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
        LEFT JOIN catalog_page cp
            ON cp.cp_start_date_sk = d.d_date_sk
        LEFT JOIN web_page wp
            ON wp.wp_creation_date_sk = d.d_date_sk
        LEFT JOIN (
            SELECT *
            FROM inventory TABLESAMPLE BERNOULLI (10)
        ) inv
            ON inv.inv_date_sk = d.d_date_sk
        CROSS JOIN LATERAL (
            SELECT avg(i2.inv_quantity_on_hand) AS avg_qty_for_item
            FROM inventory i2
            WHERE i2.inv_item_sk = inv.inv_item_sk
        ) inv_lateral
    WHERE
        d.d_year = 1998
        AND d.d_quarter_seq = 6
        AND sm.sm_type = 'AIR'
        AND cp.cp_type = 'Seasonal'
        AND cd.cd_gender = 'M'
        AND ws.ws_quantity > 2
        AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        sm.sm_ship_mode_id
)
SELECT
    a.d_date,
    a.d_year,
    a.d_quarter_name,
    a.sm_ship_mode_id,
    a.store_sales_amount,
    a.web_sales_amount,
    a.catalog_return_amount,
    a.store_return_amount,
    a.total_inventory,
    CASE
        WHEN (a.store_sales_amount + a.web_sales_amount) > 20000 THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    RANK() OVER (PARTITION BY a.d_year ORDER BY (a.store_sales_amount + a.web_sales_amount) DESC) AS sales_rank,
    AVG(a.store_sales_amount + a.web_sales_amount) OVER (PARTITION BY a.d_quarter_name) AS avg_sales_per_quarter
FROM
    aggregated a
WHERE
    CASE
        WHEN (a.store_sales_amount + a.web_sales_amount) > 20000 THEN 'High'
        ELSE 'Low'
    END = 'High'
    AND (a.store_sales_amount + a.web_sales_amount) > 5000
ORDER BY
    sales_category DESC,
    a.total_inventory DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
