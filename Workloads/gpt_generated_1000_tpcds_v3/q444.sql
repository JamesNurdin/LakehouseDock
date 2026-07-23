WITH ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_ship_cdemo_sk,
        ws_ship_hdemo_sk,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        MIN(ws_net_paid_inc_ship) AS min_net_paid,
        MAX(ws_net_paid_inc_ship) AS max_net_paid
    FROM web_sales
    WHERE ws_quantity > 5
      AND ws_net_paid_inc_ship > 1000
    GROUP BY
        ws_sold_date_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_ship_cdemo_sk,
        ws_ship_hdemo_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    d.d_year,
    cp.cp_department,
    cd_bill.cd_gender,
    SUM(ws_agg.total_net_paid) AS total_sales,
    AVG(ws_agg.total_net_paid) AS avg_sales,
    SUM(ws_agg.sales_cnt) AS total_orders,
    MIN(ws_agg.min_net_paid) AS min_sales,
    MAX(ws_agg.max_net_paid) AS max_sales,
    CASE
        WHEN SUM(ws_agg.total_net_paid) > 500000 THEN 'High'
        ELSE 'Low'
    END AS sales_category
FROM ws_agg
JOIN date_dim d
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
JOIN customer_demographics cd_bill
    ON ws_agg.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws_agg.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON ws_agg.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws_agg.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE d.d_year = 2001
  AND cd_bill.cd_gender = 'M'
  AND hd_bill.hd_income_band_sk BETWEEN 10 AND 15
  AND s.s_state = 'CA'
  AND cp.cp_department = 'Electronics'
GROUP BY
    s.s_store_id,
    s.s_state,
    d.d_year,
    cp.cp_department,
    cd_bill.cd_gender
ORDER BY total_sales DESC
LIMIT 100
