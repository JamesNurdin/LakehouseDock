/*
Goal: Identify the most profitable stores for the year 2001 where sales were made to male customers in California, the store has large floor space, and shipments used the 'AIR' ship mode. The query joins all eight selected tables, aggregates sales and returns per store/year, computes net profit, compares it against overall averages via scalar sub‑queries, ranks stores by profit, and returns the top 100.
*/
WITH sales_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_floor_space,
        d_sales.d_year AS sales_year,
        SUM(cs.cs_net_paid)                                   AS total_sales,
        SUM(COALESCE(cr.cr_net_loss, 0))                      AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk      = cr.cr_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND ca_bill.ca_state = 'CA'
      AND cd_bill.cd_gender = 'M'
      AND s.s_floor_space > 8000000
      AND sm.sm_type = 'AIR'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_floor_space,
        d_sales.d_year
)
SELECT
    sr.s_store_id,
    sr.s_store_name,
    sr.sales_year,
    sr.total_sales,
    sr.total_returns,
    (sr.total_sales - sr.total_returns)                         AS net_profit,
    (SELECT AVG(total_sales)
       FROM sales_returns sr2
       WHERE sr2.sales_year = sr.sales_year)                   AS avg_yearly_sales,
    RANK() OVER (ORDER BY (sr.total_sales - sr.total_returns) DESC) AS profit_rank
FROM sales_returns sr
WHERE (sr.total_sales - sr.total_returns) >
      (SELECT AVG(total_sales - total_returns) FROM sales_returns)
ORDER BY net_profit DESC
LIMIT 100
