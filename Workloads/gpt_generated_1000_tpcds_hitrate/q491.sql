SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    concat(cc.cc_city, '-', cc.cc_state) AS location,
    sum(cs.cs_net_profit) AS total_profit,
    count(*) AS order_cnt,
    CASE WHEN sum(cs.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY sum(cs.cs_net_profit) DESC) AS global_rank,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY sum(cs.cs_net_profit) DESC) AS state_rank
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    regexp_like(cc.cc_hours, '^8AM')
    AND ca.ca_city LIKE '%York%'
    AND regexp_extract(ca.ca_street_type, '(Road)', 1) = 'Road'
    AND cs.cs_call_center_sk IN (
        SELECT cs2.cs_call_center_sk
        FROM catalog_sales cs2
        JOIN customer_address ca2
          ON cs2.cs_ship_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_suite_number LIKE 'Suite 0%'
    )
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
