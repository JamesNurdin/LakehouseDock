WITH catalog_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        hd.hd_buy_potential,
        sm.sm_carrier,
        sm.sm_code
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
joined_chain AS (
    SELECT
        cb.*, 
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        s.s_store_name,
        s.s_state AS store_state,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        ws.web_name
    FROM catalog_base cb
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = cb.cs_sold_date_sk
        AND ss.ss_sold_time_sk = cb.cs_sold_time_sk
        AND ss.ss_customer_sk = cb.cs_bill_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_date_sk = cb.cs_sold_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = cb.cs_sold_date_sk
        AND wr.wr_returned_time_sk = cb.cs_sold_time_sk
        AND wr.wr_refunded_customer_sk = cb.cs_bill_customer_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = cb.cs_sold_date_sk
)
SELECT
    d_year,
    ca_state,
    sm_carrier,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price) DESC) AS rn_year
FROM joined_chain
WHERE d_year BETWEEN 1999 AND 2002
  AND ca_state IN ('TX', 'CA', 'NY')
  AND sm_carrier = 'FEDEX'
  AND hd_buy_potential = '>10000'
GROUP BY d_year, ca_state, sm_carrier
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
