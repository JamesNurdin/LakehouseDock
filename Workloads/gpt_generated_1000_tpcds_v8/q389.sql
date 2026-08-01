WITH rc_full AS (
    SELECT
        cc.cc_call_center_id,
        cr.cr_order_number,
        sm.sm_type,
        w.w_city,
        i.inv_quantity_on_hand
    FROM call_center cc
    FULL OUTER JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
),
rc_agg AS (
    SELECT
        COUNT(*) AS rc_cnt,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM rc_full
),
sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        CASE
            WHEN cd.cd_education_status = 'College' THEN 'College'
            WHEN cd.cd_education_status = 'Advanced Degree' THEN 'Advanced'
            ELSE 'Other'
        END AS edu_group,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(ss.ss_ext_tax) AS tax,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(*) AS tx_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_sales_price > 50
      AND NOT EXISTS (
          SELECT 1 FROM inventory i WHERE i.inv_item_sk = ss.ss_item_sk
      )
    GROUP BY cd.cd_gender,
        CASE
            WHEN cd.cd_education_status = 'College' THEN 'College'
            WHEN cd.cd_education_status = 'Advanced Degree' THEN 'Advanced'
            ELSE 'Other'
        END
),
web_agg AS (
    SELECT
        cd.cd_gender AS gender,
        CASE
            WHEN cd.cd_education_status = 'College' THEN 'College'
            WHEN cd.cd_education_status = 'Advanced Degree' THEN 'Advanced'
            ELSE 'Other'
        END AS edu_group,
        SUM(ws.ws_ext_sales_price) AS sales,
        SUM(ws.ws_ext_tax) AS tax,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS tx_cnt
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_quantity > 1
      AND ws.ws_sales_price > 50
      AND NOT EXISTS (
          SELECT 1 FROM inventory i WHERE i.inv_item_sk = ws.ws_item_sk
      )
    GROUP BY cd.cd_gender,
        CASE
            WHEN cd.cd_education_status = 'College' THEN 'College'
            WHEN cd.cd_education_status = 'Advanced Degree' THEN 'Advanced'
            ELSE 'Other'
        END
),
union_all_sales AS (
    SELECT gender, edu_group, sales, tax, profit, tx_cnt FROM sales_agg
    UNION ALL
    SELECT gender, edu_group, sales, tax, profit, tx_cnt FROM web_agg
),
base AS (
    SELECT
        gender,
        edu_group,
        SUM(sales) AS total_sales,
        SUM(tax) AS total_tax,
        SUM(profit) AS total_profit,
        SUM(tx_cnt) AS total_tx
    FROM union_all_sales
    GROUP BY gender, edu_group
),
final AS (
    SELECT
        b.*,
        SUM(b.total_sales) OVER (
            PARTITION BY b.edu_group
            ORDER BY b.total_sales
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS total_sales_running
    FROM base b
)
SELECT
    f.gender,
    f.edu_group,
    f.total_sales,
    f.total_tax,
    f.total_profit,
    f.total_tx,
    f.total_sales / NULLIF(f.total_tx, 0) AS avg_sales_per_tx,
    ROW_NUMBER() OVER (PARTITION BY f.edu_group ORDER BY f.total_sales DESC) AS rank_within_edu,
    LAG(f.total_sales) OVER (PARTITION BY f.edu_group ORDER BY f.total_sales) AS previous_sales,
    f.total_sales_running,
    rc.rc_cnt,
    rc.total_inventory,
    metric_value
FROM final f
CROSS JOIN rc_agg rc
CROSS JOIN UNNEST(ARRAY[f.total_sales, f.total_tax]) AS t(metric_value)
WHERE f.total_sales > 1000
  AND f.total_profit > 0
  AND f.edu_group <> 'Other'
ORDER BY f.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
