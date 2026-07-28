WITH sales_detail AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_ext_sales_price,
       cs.cs_quantity,
       cs.cs_net_profit,
       cs.cs_ext_list_price,
       t.t_hour,
       t.t_sub_shift,
       ca.ca_state,
       ca.ca_city,
       cd.cd_gender,
       hd.hd_income_band_sk,
       hd.hd_buy_potential
   FROM catalog_sales cs
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_ext_list_price > 2000
     AND cs.cs_quantity BETWEEN 1 AND 5
     AND t.t_hour >= 8
     AND ca.ca_state = 'CA'
     AND cd.cd_gender = 'M'
     AND hd.hd_income_band_sk IN (1, 2)
)
SELECT
    sd.ca_state,
    sd.ca_city,
    sd.t_sub_shift,
    CASE
        WHEN sd.cs_net_profit > 1000 THEN 'High'
        WHEN sd.cs_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    sd.cs_ext_sales_price,
    sd.cs_quantity,
    AVG(sd.cs_ext_sales_price) OVER (PARTITION BY sd.ca_state) AS avg_state_sales,
    ROW_NUMBER() OVER (PARTITION BY sd.ca_state ORDER BY sd.cs_ext_sales_price DESC) AS rn_state_sales,
    (SELECT COUNT(*) FROM sales_detail sd2 WHERE sd2.ca_state = sd.ca_state) AS state_sales_count
FROM sales_detail sd
GROUP BY
    sd.ca_state,
    sd.ca_city,
    sd.t_sub_shift,
    CASE
        WHEN sd.cs_net_profit > 1000 THEN 'High'
        WHEN sd.cs_net_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END,
    sd.cs_ext_sales_price,
    sd.cs_quantity,
    sd.cs_net_profit
HAVING SUM(sd.cs_quantity) > 100
ORDER BY sd.ca_state, rn_state_sales
LIMIT 100
