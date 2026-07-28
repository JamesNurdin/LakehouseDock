WITH ws_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_hdemo_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '1001-5000'
      AND ws.ws_quantity > 5
    GROUP BY ws.ws_sold_date_sk, ws.ws_bill_hdemo_sk
)
SELECT
    d_outer.d_year,
    d_outer.d_quarter_name,
    s.s_store_id,
    cp.cp_department,
    hd_outer.hd_buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws_agg.total_net_paid) AS total_sales_net,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    CASE 
        WHEN SUM(ws_agg.total_net_paid) = 0 THEN 0
        ELSE SUM(cr.cr_return_amount) / SUM(ws_agg.total_net_paid)
    END AS return_to_sales_ratio
FROM catalog_returns cr
JOIN date_dim d_outer ON cr.cr_returned_date_sk = d_outer.d_date_sk
JOIN household_demographics hd_outer ON cr.cr_refunded_hdemo_sk = hd_outer.hd_demo_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store s ON s.s_closed_date_sk = d_outer.d_date_sk
JOIN ws_agg ON ws_agg.ws_sold_date_sk = d_outer.d_date_sk
               AND ws_agg.ws_bill_hdemo_sk = hd_outer.hd_demo_sk
WHERE d_outer.d_current_quarter = 'Y'
  AND cp.cp_type = 'Promotion'
  AND s.s_state = 'CA'
GROUP BY d_outer.d_year, d_outer.d_quarter_name, s.s_store_id, cp.cp_department, hd_outer.hd_buy_potential
ORDER BY d_outer.d_year DESC, total_sales_net DESC
LIMIT 100
