WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        ca.ca_city,
        ca.ca_county,
        cc.cc_name,
        cc.cc_state,
        d.d_year
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND ca.ca_city LIKE 'S%'
      AND regexp_like(ca.ca_county, '.*County$')
)
SELECT
    cc_name,
    concat(cc_name, ' (', cc_state, ')') AS cc_full_name,
    substring(cc_name, 1, 10) AS cc_name_prefix,
    sum(cs_net_profit) AS total_net_profit,
    count(DISTINCT cs_order_number) AS distinct_orders
FROM filtered_sales
GROUP BY cc_name, cc_state, substring(cc_name, 1, 10)
ORDER BY total_net_profit DESC
LIMIT 100
