WITH catalog_agg AS (
    SELECT
        cp.cp_department AS category,
        ca.ca_state AS state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        ARRAY['sales','discount'] AS metric_names,
        ARRAY[SUM(cs.cs_ext_sales_price), SUM(cs.cs_ext_discount_amt)] AS metric_vals
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450996 AND 2451452
      AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
    GROUP BY cp.cp_department, ca.ca_state
),
returns_agg AS (
    SELECT
        r.r_reason_desc AS category,
        ca.ca_state AS state,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_fee) AS total_fee,
        ARRAY['return_amt','fee'] AS metric_names,
        ARRAY[SUM(wr.wr_return_amt), SUM(wr.wr_fee)] AS metric_vals
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_amt > 100
      AND EXISTS (
          SELECT 1 FROM item i WHERE i.i_item_sk = wr.wr_item_sk AND i.i_color = 'red'
      )
    GROUP BY r.r_reason_desc, ca.ca_state
)
SELECT *
FROM (
    SELECT
        'catalog' AS source_type,
        ca.category,
        ca.state,
        u.metric_name,
        u.metric_val
    FROM catalog_agg ca
    CROSS JOIN UNNEST(ca.metric_names, ca.metric_vals) AS u(metric_name, metric_val)
    UNION ALL
    SELECT
        'return' AS source_type,
        ra.category,
        ra.state,
        u.metric_name,
        u.metric_val
    FROM returns_agg ra
    CROSS JOIN UNNEST(ra.metric_names, ra.metric_vals) AS u(metric_name, metric_val)
) combined
ORDER BY metric_val DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
