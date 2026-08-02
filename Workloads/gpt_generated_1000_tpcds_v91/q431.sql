WITH cs_sales_no_ret AS (
    SELECT *
    FROM catalog_sales cs
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = cs.cs_item_sk
          AND sr.sr_customer_sk = cs.cs_bill_customer_sk
    )
),
cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_catalog_page_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sale_cnt
    FROM cs_sales_no_ret
    WHERE cs_quantity > 0
    GROUP BY cs_call_center_sk, cs_warehouse_sk, cs_sold_date_sk, cs_bill_hdemo_sk, cs_bill_addr_sk, cs_catalog_page_sk
),
sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_addr_sk,
        sr_hdemo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_returned_date_sk, sr_addr_sk, sr_hdemo_sk
),
cc_hours AS (
    SELECT
        cc.cc_call_center_sk,
        hour_val
    FROM call_center cc
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_val)
    WHERE cc.cc_hours IS NOT NULL
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    cc.cc_name,
    wh.w_warehouse_name,
    cp.cp_department,
    SUM(cs_agg.total_net_paid) AS total_sales,
    SUM(cs_agg.total_quantity) AS total_quantity,
    SUM(cs_agg.sale_cnt) AS total_sales_count,
    SUM(sr_agg.total_return_amt) AS total_return_amount,
    SUM(sr_agg.return_cnt) AS total_return_count,
    COUNT(DISTINCT cc_hour.hour_val) AS distinct_hour_segments
FROM cs_agg
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN cc_hours cc_hour ON cc.cc_call_center_sk = cc_hour.cc_call_center_sk
JOIN warehouse wh ON cs_agg.cs_warehouse_sk = wh.w_warehouse_sk
JOIN date_dim d_sold ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN sr_agg ON sr_agg.sr_addr_sk = ca.ca_address_sk
    AND sr_agg.sr_hdemo_sk = hd.hd_demo_sk
    AND sr_agg.sr_returned_date_sk = d_sold.d_date_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_country = 'United States'
  AND wh.w_country = 'United States'
  AND d_sold.d_year = 1999
  AND d_sold.d_month_seq = 12
  AND hd.hd_income_band_sk IN (3, 5, 12)
  AND hd.hd_dep_count > 2
  AND cp.cp_department = 'Sports'
  AND cp.cp_type = 'catalog'
GROUP BY d_sold.d_year, d_sold.d_month_seq, cc.cc_name, wh.w_warehouse_name, cp.cp_department
ORDER BY total_sales DESC
LIMIT 100
