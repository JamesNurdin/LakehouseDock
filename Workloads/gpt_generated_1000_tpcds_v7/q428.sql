/* Goal: Calculate total net paid and average discount per customer salutation, household buying potential, hour of sale, and sales city by joining all five selected tables multiple times (using different aliases) to create a deep‑join query with nine join clauses. */
SELECT
    c.c_salutation,
    hd_customer.hd_buy_potential AS cust_buy_potential,
    hd_sales.hd_buy_potential    AS sales_buy_potential,
    td_sold.t_hour,
    ca1.ca_city                 AS sales_city,
    ca_cust.ca_city             AS cust_city,
    SUM(ss.ss_net_paid)        AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
FROM tpcds.store_sales ss
JOIN tpcds.time_dim td_sold
  ON ss.ss_sold_time_sk = td_sold.t_time_sk                                     -- join 1
JOIN tpcds.time_dim td_dummy
  ON ss.ss_sold_time_sk = td_dummy.t_time_sk                                    -- join 2 (second alias of time_dim)
JOIN tpcds.time_dim td_extra
  ON ss.ss_sold_time_sk = td_extra.t_time_sk                                    -- join 3 (third alias of time_dim)
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk                                        -- join 4
JOIN tpcds.customer_address ca1
  ON ss.ss_addr_sk = ca1.ca_address_sk                                           -- join 5 (sales address)
JOIN tpcds.customer_address ca2
  ON ss.ss_addr_sk = ca2.ca_address_sk                                           -- join 6 (second alias of address)
JOIN tpcds.household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk                                        -- join 7 (sales household demo)
JOIN tpcds.household_demographics hd_customer
  ON c.c_current_hdemo_sk = hd_customer.hd_demo_sk                               -- join 8 (customer household demo)
JOIN tpcds.customer_address ca_cust
  ON c.c_current_addr_sk = ca_cust.ca_address_sk                                 -- join 9 (customer current address)
WHERE c.c_last_review_date BETWEEN 2452400 AND 2452600
  AND hd_sales.hd_dep_count >= 3
GROUP BY
    c.c_salutation,
    hd_customer.hd_buy_potential,
    hd_sales.hd_buy_potential,
    td_sold.t_hour,
    ca1.ca_city,
    ca_cust.ca_city
ORDER BY total_net_paid DESC
LIMIT 100
