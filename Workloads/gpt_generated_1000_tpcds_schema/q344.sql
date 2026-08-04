WITH base AS (
    SELECT
        i.i_item_id,
        i.i_current_price,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        cd.cd_gender,
        hd.hd_income_band_sk,
        sm.sm_code,
        wp.wp_url,
        ws.ws_sold_date_sk,
        cs.web_site_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site cs ON ws.ws_web_site_sk = cs.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price BETWEEN 10 AND 500
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 1 AND 5
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451102
      AND cp.cp_department = 'Electronics'
),
sales_agg AS (
    SELECT i_item_id,
           SUM(ws_ext_sales_price) AS total_sales
    FROM base
    GROUP BY i_item_id
),
returns_agg AS (
    SELECT i_item_id,
           SUM(cr_return_amount) AS total_returns
    FROM base
    GROUP BY i_item_id
),
unioned AS (
    SELECT i_item_id,
           total_sales AS amount
    FROM sales_agg
    UNION
    SELECT i_item_id,
           total_returns AS amount
    FROM returns_agg
),
combined AS (
    SELECT i_item_id,
           SUM(amount) AS combined_amount
    FROM unioned
    GROUP BY i_item_id
    HAVING SUM(amount) > 1000
),
excluded AS (
    SELECT i_item_id,
           combined_amount
    FROM combined
    WHERE combined_amount < 2000
)
SELECT i_item_id,
       combined_amount
FROM combined
EXCEPT
SELECT i_item_id,
       combined_amount
FROM excluded
ORDER BY combined_amount DESC
LIMIT 100
