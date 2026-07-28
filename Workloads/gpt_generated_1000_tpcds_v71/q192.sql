/* goal: Compare total sales amount from web sales with total return amount from catalog returns by warehouse and household income band for December 2001. */
WITH catalog_agg AS (
    SELECT
        w.w_warehouse_id        AS warehouse_id,
        hd.hd_income_band_sk    AS income_band,
        SUM(cr.cr_return_amount) AS total_amount,
        'catalog'               AS source
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_moy  = 12
    GROUP BY w.w_warehouse_id, hd.hd_income_band_sk
),
web_agg AS (
    SELECT
        w.w_warehouse_id        AS warehouse_id,
        hd.hd_income_band_sk    AS income_band,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        'web'                   AS source
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_moy  = 12
    GROUP BY w.w_warehouse_id, hd.hd_income_band_sk
)
SELECT
    warehouse_id,
    income_band,
    total_amount,
    source
FROM catalog_agg
UNION ALL
SELECT
    warehouse_id,
    income_band,
    total_amount,
    source
FROM web_agg
ORDER BY total_amount DESC
LIMIT 100
