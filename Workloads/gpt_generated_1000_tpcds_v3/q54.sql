WITH filtered_sales AS (
    SELECT
        s.s_division_id,
        i.i_brand,
        s.s_store_id,
        c.c_last_name,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
      AND c.c_email_address LIKE '%example.com'
      AND sm.sm_carrier = 'USPS'
)
SELECT
    s_division_id,
    i_brand,
    concat(s_store_id, '_', substr(c_last_name, 1, 3)) AS store_customer_key,
    sum(ss_net_paid) AS total_store_sales_net_paid,
    sum(cs_net_paid) AS total_catalog_sales_net_paid,
    sum(ss_net_profit) AS total_store_sales_net_profit,
    sum(cs_net_profit) AS total_catalog_sales_net_profit
FROM filtered_sales
GROUP BY
    s_division_id,
    i_brand,
    s_store_id,
    substr(c_last_name, 1, 3)
ORDER BY total_store_sales_net_paid DESC
LIMIT 100
