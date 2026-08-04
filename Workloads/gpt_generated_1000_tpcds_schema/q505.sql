WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    WHERE inv_warehouse_sk IN (19, 8)
      AND inv_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    company_name,
    warehouse_name,
    year,
    month,
    total_qty,
    sales_sum,
    sales_avg,
    order_count,
    sales_category,
    rn
FROM (
    -- First branch: catalog_sales
    SELECT
        cc.cc_company_name AS company_name,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        d.d_month_seq AS month,
        ia.total_qty,
        SUM(cs.cs_net_paid) AS sales_sum,
        AVG(cs.cs_net_paid) AS sales_avg,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cs.cs_net_paid) DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    RIGHT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inv_agg ia ON ia.inv_warehouse_sk = w.w_warehouse_sk AND ia.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_company_name = 'pri'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY cc.cc_company_name, w.w_warehouse_name, d.d_year, d.d_month_seq, ia.total_qty

    UNION DISTINCT

    -- Second branch: web_sales
    SELECT
        cc2.cc_company_name AS company_name,
        w2.w_warehouse_name AS warehouse_name,
        d2.d_year AS year,
        d2.d_month_seq AS month,
        ia2.total_qty,
        SUM(ws.ws_net_paid) AS sales_sum,
        AVG(ws.ws_net_paid) AS sales_avg,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY w2.w_warehouse_name ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    RIGHT JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN call_center cc2 ON cc2.cc_open_date_sk = d2.d_date_sk
    LEFT JOIN inv_agg ia2 ON ia2.inv_warehouse_sk = w2.w_warehouse_sk AND ia2.inv_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND cc2.cc_company_name = 'pri'
      AND hd2.hd_buy_potential = '>10000'
    GROUP BY cc2.cc_company_name, w2.w_warehouse_name, d2.d_year, d2.d_month_seq, ia2.total_qty
) AS combined
LIMIT 100
