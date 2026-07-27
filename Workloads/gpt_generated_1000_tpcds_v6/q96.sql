WITH fact_all AS (
   SELECT
      ss_customer_sk AS cust_sk,
      ss_cdemo_sk AS cdemo_sk,
      ss_item_sk AS item_sk,
      ss_ticket_number AS ticket_number,
      ss_sold_date_sk AS sales_date_sk,
      ss_ext_sales_price AS sales_amount,
      CAST(NULL AS integer) AS ws_web_page_sk
   FROM store_sales
   UNION ALL
   SELECT
      ws_bill_customer_sk AS cust_sk,
      ws_bill_cdemo_sk AS cdemo_sk,
      ws_item_sk AS item_sk,
      ws_order_number AS ticket_number,
      ws_sold_date_sk AS sales_date_sk,
      ws_ext_sales_price AS sales_amount,
      ws_web_page_sk
   FROM web_sales
),
distinct_facts AS (
   SELECT DISTINCT
      cust_sk,
      cdemo_sk,
      item_sk,
      ticket_number,
      sales_date_sk,
      sales_amount,
      ws_web_page_sk
   FROM fact_all
)
SELECT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   cd.cd_gender,
   SUM(df.sales_amount) AS total_sales,
   SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunds,
   CASE WHEN SUM(COALESCE(sr.sr_refunded_cash, 0)) > 500 THEN 'High' ELSE 'Low' END AS refund_level,
   ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(df.sales_amount) DESC) AS gender_rank
FROM distinct_facts df
JOIN customer c
  ON df.cust_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON df.cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
  ON df.ticket_number = sr.sr_ticket_number
  AND df.item_sk = sr.sr_item_sk
LEFT JOIN web_page wp
  ON df.ws_web_page_sk = wp.wp_web_page_sk
WHERE
   c.c_birth_year BETWEEN 1960 AND 1970
   AND c.c_preferred_cust_flag = 'Y'
   AND cd.cd_gender = 'M'
   AND sr.sr_refunded_cash > 100
   AND wp.wp_autogen_flag = 'N'
   AND df.sales_date_sk BETWEEN 2451900 AND 2452000
GROUP BY
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   cd.cd_gender
HAVING
   SUM(df.sales_amount) > 1000
ORDER BY
   total_sales DESC
LIMIT 100
