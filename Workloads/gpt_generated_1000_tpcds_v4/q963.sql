WITH distinct_items AS (
    SELECT DISTINCT i_item_sk, i_item_id
    FROM item
    WHERE i_brand = 'Brand#12'
),

sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        AVG(cs.cs_quantity) AS avg_catalog_qty,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN distinct_items di ON cs.cs_item_sk = di.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'F'
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_bill_cdemo_sk
),

returns_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN distinct_items di_ret ON sr.sr_item_sk = di_ret.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE d_ret.d_year = 2001
      AND s.s_number_employees > 250
      AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk, sr.sr_store_sk
)

SELECT
    d_ws.d_date,
    di.i_item_id,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    sa.total_catalog_sales,
    ra.total_return_amt
FROM web_sales ws
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN distinct_items di ON ws.ws_item_sk = di.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN sales_agg sa ON ws.ws_sold_date_sk = sa.cs_sold_date_sk
               AND ws.ws_item_sk = sa.cs_item_sk
               AND ws.ws_bill_cdemo_sk = sa.cs_bill_cdemo_sk
LEFT JOIN returns_agg ra ON ws.ws_sold_date_sk = ra.sr_returned_date_sk
                         AND ws.ws_item_sk = ra.sr_item_sk
WHERE d_ws.d_year = 2001
  AND sm_ws.sm_type = 'AIR'
  AND cd_ws.cd_gender = 'F'
GROUP BY d_ws.d_date, di.i_item_id, sa.total_catalog_sales, ra.total_return_amt
ORDER BY total_web_sales DESC
LIMIT 100
