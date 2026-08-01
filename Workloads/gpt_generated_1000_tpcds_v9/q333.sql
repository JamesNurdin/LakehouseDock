WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        cc.cc_name AS call_center_name,
        hd.hd_vehicle_count,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_return_amt,
        c.c_customer_sk
    FROM date_dim d
    INNER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN store s ON s.s_store_sk = sr.sr_store_sk
    INNER JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
    INNER JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    INNER JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    INNER JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    INNER JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    INNER JOIN web_site web ON web.web_site_sk = ws.ws_web_site_sk
    WHERE d.d_year = 1999
      AND cc.cc_state = 'CA'
      AND w.w_state = 'TX'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_return_amt > 200
      )
),
agg AS (
    SELECT
        d_year,
        s_store_id,
        s_store_name,
        call_center_name,
        hd_vehicle_count,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(sr_return_amt) AS total_returns,
        (SUM(cs_ext_sales_price) + SUM(ws_ext_sales_price) - SUM(sr_return_amt)) AS net_sales
    FROM base
    GROUP BY d_year, s_store_id, s_store_name, call_center_name, hd_vehicle_count
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    call_center_name,
    CASE
        WHEN hd_vehicle_count > 1 THEN 'Multiple Vehicles'
        WHEN hd_vehicle_count = 1 THEN 'One Vehicle'
        ELSE 'No Vehicle'
    END AS vehicle_category,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    net_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_sales DESC) AS sales_rank_year
FROM agg
ORDER BY d_year DESC, sales_rank_year
LIMIT 100
