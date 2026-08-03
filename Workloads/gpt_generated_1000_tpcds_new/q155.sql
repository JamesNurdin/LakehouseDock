WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 500
      AND cs.cs_ext_discount_amt < 5000
      AND cs.cs_ext_list_price >= 1000
      AND cs.cs_ext_list_price <= 5000
      AND cs.cs_net_profit > 0
      AND cs.cs_quantity >= 1
      AND cs.cs_ship_date_sk > 1500
    GROUP BY cs.cs_call_center_sk
),
intersected_cc AS (
    SELECT cc_call_center_sk
    FROM (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_class = 'large'
          AND cc_division IN (2, 3, 4)
          AND cc_country = 'United States'
          AND cc_gmt_offset BETWEEN -5 AND 0
          AND cc_tax_percentage > 5
          AND cc_employees > 200
    )
    INTERSECT
    SELECT cc_call_center_sk
    FROM (
        SELECT cc_call_center_sk
        FROM call_center
        WHERE cc_company_name LIKE '%pri%'
          AND cc_state = 'CA'
          AND cc_city LIKE 'San%'
          AND cc_zip LIKE '9%'
          AND cc_employees BETWEEN 100 AND 500
          AND cc_gmt_offset < 1
    )
),
hours_expanded AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        hour
    FROM call_center cc
    JOIN intersected_cc ic ON cc.cc_call_center_sk = ic.cc_call_center_sk
    CROSS JOIN UNNEST(split(cc.cc_hours, ';')) AS t(hour)
)
SELECT
    he.cc_name,
    he.cc_city,
    he.hour,
    sa.total_net_paid,
    sa.order_cnt,
    sa.total_net_paid / sa.order_cnt AS avg_paid_per_order
FROM hours_expanded he
JOIN sales_agg sa ON he.cc_call_center_sk = sa.cs_call_center_sk
WHERE sa.total_net_paid > 1000
  AND sa.order_cnt >= 5
ORDER BY sa.total_net_paid DESC
LIMIT 100
