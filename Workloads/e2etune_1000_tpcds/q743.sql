WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid_inc_ship AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        t.t_hour AS hour,
        cc.cc_division_name AS division,
        cc.cc_company AS company,
        cp.cp_department AS department,
        cp.cp_type AS page_type
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_hours = '8AM-4PM'
      AND cc.cc_street_type = 'Boulevard'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date < DATE '2002-01-01'
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'
)
SELECT
    hour,
    division,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(net_profit) / NULLIF(SUM(net_paid), 0), 4) AS profit_margin
FROM filtered_sales
GROUP BY GROUPING SETS (
    (hour, division),
    (hour),
    (division),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 200
