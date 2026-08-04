WITH
  cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
  ),
  cs_cust_keys AS (
    SELECT cs_bill_customer_sk AS cust_sk
    FROM cs_sample
  ),
  ss_cust_keys AS (
    SELECT ss_customer_sk AS cust_sk
    FROM store_sales
  ),
  common_cust AS (
    SELECT cust_sk FROM cs_cust_keys
    INTERSECT
    SELECT cust_sk FROM ss_cust_keys
  ),
  ss_agg AS (
    SELECT ss_store_sk,
           SUM(ss_net_paid) AS agg_net_paid,
           COUNT(*)      AS agg_cnt
    FROM store_sales
    GROUP BY ss_store_sk
  )
SELECT
  COALESCE(s.s_store_name, 'All Stores')                                 AS store_name,
  COALESCE(c.c_first_name || ' ' || c.c_last_name, 'All Customers')    AS customer_name,
  SUM(CASE WHEN r.r_reason_desc LIKE '%price%'
           THEN cs.cs_ext_sales_price
           ELSE 0
      END)                                                            AS price_reason_sales,
  SUM(cs.cs_ext_sales_price)                                            AS total_catalog_sales,
  SUM(ss_agg.agg_net_paid)                                             AS total_store_sales,
  COUNT(DISTINCT cs.cs_order_number)                                    AS distinct_orders,
  GROUPING(s.s_store_name)                                              AS grp_store,
  GROUPING(c.c_first_name, c.c_last_name)                              AS grp_customer
FROM
  time_dim td
  LEFT JOIN cs_sample cs
    ON cs.cs_sold_time_sk = td.t_time_sk
  LEFT JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  -- full outer join between store_sales and store_returns on ticket number
  FULL OUTER JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN ss_agg
    ON ss_agg.ss_store_sk = s.s_store_sk
WHERE
  td.t_hour BETWEEN 9 AND 17
  AND c.c_customer_sk IN (SELECT cust_sk FROM common_cust)
GROUP BY ROLLUP (s.s_store_name, c.c_first_name, c.c_last_name)
ORDER BY store_name, customer_name
LIMIT 100
