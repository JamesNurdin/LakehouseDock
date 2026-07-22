SELECT
    cc.cc_name,
    d.d_year,
    sm.sm_type,
    cd.cd_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    COUNT(*) AS order_count,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid,
    SUM(cs.cs_quantity) AS total_quantity
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    d.d_holiday = 'N'
    AND d.d_current_quarter = 'Y'
    AND d.d_quarter_name = '1903Q1'
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND sm.sm_type = 'OVERNIGHT'
    AND sm.sm_code = 'AIR'
    AND cc.cc_state = 'CA'
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 1000
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_sold_date_sk = d.d_date_sk
          AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
          AND ws.ws_net_paid > 5000
    )
GROUP BY
    cc.cc_name,
    d.d_year,
    sm.sm_type,
    cd.cd_gender
ORDER BY
    total_net_paid DESC
LIMIT 100
