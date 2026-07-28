WITH cs_agg AS (
    SELECT
        d.d_year AS year,
        cc.cc_name AS segment,
        i.i_category AS category,
        sm.sm_type AS subsegment,
        SUM(cs.cs_ext_sales_price) AS metric_value,
        'sales' AS metric_type,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS level
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND cp.cp_type = 'Electronics'
    GROUP BY GROUPING SETS (
        (d.d_year, cc.cc_name, i.i_category, sm.sm_type),
        (d.d_year, cc.cc_name, i.i_category),
        (d.d_year, cc.cc_name),
        (d.d_year)
    )
),
wr_agg AS (
    SELECT
        d.d_year AS year,
        wp.wp_type AS segment,
        i.i_category AS category,
        NULL AS subsegment,
        SUM(wr.wr_return_amt) AS metric_value,
        'returns' AS metric_type,
        CASE WHEN SUM(wr.wr_return_amt) > 50000 THEN 'High' ELSE 'Low' END AS level
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND wp.wp_type = 'Content'
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = wr.wr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
    GROUP BY ROLLUP (d.d_year, wp.wp_type, i.i_category)
)
SELECT
    year,
    segment,
    category,
    subsegment,
    metric_value,
    metric_type,
    level
FROM cs_agg
UNION ALL
SELECT
    year,
    segment,
    category,
    subsegment,
    metric_value,
    metric_type,
    level
FROM wr_agg
ORDER BY year DESC, metric_value DESC
LIMIT 100
