-- goal: Compare aggregated sales from the catalog and web channels for high‑income customers in 2001, showing item, customer and shipping details, and the number of web returns per item/date.
WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_bill_customer_sk,
        cs_ship_mode_sk,
        cs_bill_hdemo_sk,
        SUM(cs_net_paid)      AS total_net_paid,
        SUM(cs_quantity)      AS total_quantity,
        COUNT(*)              AS order_cnt
    FROM tpcds.catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_bill_customer_sk, cs_ship_mode_sk, cs_bill_hdemo_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_ship_mode_sk,
        ws_bill_hdemo_sk,
        ws_web_site_sk,
        SUM(ws_net_paid)      AS total_net_paid,
        SUM(ws_quantity)      AS total_quantity,
        COUNT(*)              AS order_cnt
    FROM tpcds.web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_bill_customer_sk, ws_ship_mode_sk, ws_bill_hdemo_sk, ws_web_site_sk
)
SELECT
    'catalog'               AS source,
    c.c_customer_id,
    d.d_date,
    i.i_item_id,
    sm.sm_type,
    ib.ib_lower_bound,
    ca.total_net_paid,
    ca.total_quantity,
    ca.order_cnt,
    (SELECT COUNT(*)
       FROM tpcds.web_returns wr
       WHERE wr.wr_item_sk = i.i_item_sk
         AND wr.wr_returned_date_sk = d.d_date_sk) AS return_cnt,
    CAST(NULL AS varchar)  AS web_name
FROM cs_agg ca
JOIN tpcds.customer c               ON ca.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d               ON ca.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.item i                    ON ca.cs_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm              ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.household_demographics hd ON ca.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 2001
  AND i.i_class_id IN (7, 9, 13)
  AND ib.ib_lower_bound >= 50000
  AND sm.sm_type = 'AIR'

UNION ALL

SELECT
    'web'                  AS source,
    c.c_customer_id,
    d.d_date,
    i.i_item_id,
    sm.sm_type,
    ib.ib_lower_bound,
    wa.total_net_paid,
    wa.total_quantity,
    wa.order_cnt,
    (SELECT COUNT(*)
       FROM tpcds.web_returns wr
       WHERE wr.wr_item_sk = i.i_item_sk
         AND wr.wr_returned_date_sk = d.d_date_sk) AS return_cnt,
    ws.web_name
FROM ws_agg wa
JOIN tpcds.customer c               ON wa.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d               ON wa.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.item i                    ON wa.ws_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm              ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.household_demographics hd ON wa.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.web_site ws               ON wa.ws_web_site_sk = ws.web_site_sk
WHERE d.d_year = 2001
  AND i.i_class_id IN (7, 9, 13)
  AND ib.ib_lower_bound >= 50000
  AND sm.sm_type = 'AIR'

ORDER BY source, total_net_paid DESC
LIMIT 100
