/*
  Total sales, profit, discount and profit‑margin by billing state and gender for the calendar year 2001.
  The query joins the sales fact to the date dimension (sold date), the billing address and the billing demographic
  using only the allowed surrogate‑key relationships.
*/
WITH sales_state_gender AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
)
SELECT
    ca_state,
    cd_gender,
    sum(cs_ext_sales_price) AS total_sales,
    sum(cs_net_profit) AS total_profit,
    avg(cs_ext_discount_amt) AS avg_discount,
    count(distinct cs_order_number) AS order_cnt,
    sum(cs_net_profit) / nullif(sum(cs_ext_sales_price), 0) AS profit_margin
FROM sales_state_gender
GROUP BY ca_state, cd_gender
ORDER BY total_sales DESC
LIMIT 10
