WITH
cs_filtered AS (
    SELECT
        d.d_date AS sales_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE 
            WHEN SUM(cs.cs_quantity) > 10 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
    )
    AND NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_start_date_sk <= cs.cs_sold_date_sk
          AND p.p_end_date_sk >= cs.cs_sold_date_sk
    )
    GROUP BY d.d_date
),
sr_agg AS (
    SELECT sr.sr_returned_date_sk, SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
),
sr_with_date AS (
    SELECT sr_agg.sr_returned_date_sk, d.d_date, sr_agg.total_return_amount
    FROM sr_agg
    JOIN date_dim d ON sr_agg.sr_returned_date_sk = d.d_date_sk
),
ws_agg AS (
    SELECT ws.ws_sold_date_sk, SUM(ws.ws_net_paid) AS total_web_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
ws_with_date AS (
    SELECT ws_agg.ws_sold_date_sk, d.d_date, ws_agg.total_web_sales
    FROM ws_agg
    JOIN date_dim d ON ws_agg.ws_sold_date_sk = d.d_date_sk
),
sr_ws_full AS (
    SELECT
        COALESCE(sr_with_date.d_date, ws_with_date.d_date) AS sales_date,
        COALESCE(sr_with_date.total_return_amount, CAST(0 AS decimal(7,2))) AS total_return_amount,
        COALESCE(ws_with_date.total_web_sales, CAST(0 AS decimal(7,2))) AS total_web_sales,
        CASE
            WHEN COALESCE(ws_with_date.total_web_sales, CAST(0 AS decimal(7,2))) - COALESCE(sr_with_date.total_return_amount, CAST(0 AS decimal(7,2))) > 0
                THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status
    FROM sr_with_date
    FULL OUTER JOIN ws_with_date
        ON sr_with_date.d_date = ws_with_date.d_date
)
SELECT *
FROM (
    SELECT
        cs_filtered.sales_date,
        cs_filtered.total_sales,
        cs_filtered.total_profit,
        cs_filtered.volume_category,
        CAST(NULL AS decimal(7,2)) AS total_return_amount,
        CAST(NULL AS decimal(7,2)) AS total_web_sales,
        CAST(NULL AS varchar) AS profit_status
    FROM cs_filtered

    UNION ALL

    SELECT
        sr_ws_full.sales_date,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        CAST(NULL AS decimal(7,2)) AS total_profit,
        CAST(NULL AS varchar) AS volume_category,
        sr_ws_full.total_return_amount,
        sr_ws_full.total_web_sales,
        sr_ws_full.profit_status
    FROM sr_ws_full
) combined
ORDER BY combined.sales_date DESC
OFFSET 0 LIMIT 100
