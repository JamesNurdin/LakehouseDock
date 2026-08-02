SELECT
    cc.cc_name,
    t.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    MAX(l.max_wr_return_amt) AS max_web_return_amt_for_hour,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'Very High'
        WHEN SUM(cs.cs_net_profit) > 50000 THEN 'High'
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_band
FROM
    catalog_sales cs
    RIGHT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT MAX(wr2.wr_return_amt) AS max_wr_return_amt
        FROM web_returns wr2
        WHERE wr2.wr_returned_time_sk = t.t_time_sk
    ) AS l
WHERE
    cc.cc_country = 'United States'
    AND cp.cp_department = 'Electronics'
    AND t.t_hour IN (9, 12, 15)
    AND t.t_minute <= 30
    AND cs.cs_quantity > 5
    AND cs.cs_net_profit > 0
    AND wr.wr_return_amt > 100
    AND cr.cr_return_amount > 0
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 100
    )
GROUP BY
    ROLLUP (cc.cc_name, t.t_hour)
ORDER BY
    cc.cc_name,
    t.t_hour
