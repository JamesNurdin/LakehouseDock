/*
Goal: Analyze net financial performance by linking sales and returns at the ticket level, breaking out by sale/return year, state, and customer gender. The query joins all five tables, re‑uses date, address, and demographic dimensions under multiple aliases to reach at least nine join clauses, aggregates metrics, applies filters, includes a scalar EXISTS subquery, orders by net gain and limits the output.
*/
WITH sales_agg AS (
   SELECT
       ss_ticket_number,
       ss_item_sk,
       ss_sold_date_sk,
       ss_cdemo_sk,
       ss_addr_sk,
       SUM(ss_net_paid)        AS total_sales,
       SUM(ss_net_profit)      AS total_profit
   FROM store_sales
   GROUP BY
       ss_ticket_number,
       ss_item_sk,
       ss_sold_date_sk,
       ss_cdemo_sk,
       ss_addr_sk
)
SELECT
   d_sale.d_year                         AS sale_year,
   d_ret.d_year                          AS return_year,
   ca_sales.ca_state                     AS sale_state,
   ca_return.ca_state                    AS return_state,
   cd_sales.cd_gender                    AS sale_gender,
   cd_return.cd_gender                   AS return_gender,
   SUM(s.total_sales)                    AS sum_sales,
   SUM(r.sr_return_amt)                  AS sum_returns,
   (SUM(s.total_profit) - SUM(r.sr_net_loss)) AS net_gain
FROM sales_agg s
JOIN store_returns r
     ON s.ss_ticket_number = r.sr_ticket_number                                   -- join 1
JOIN date_dim d_sale
     ON s.ss_sold_date_sk = d_sale.d_date_sk                                      -- join 2
JOIN date_dim d_ret
     ON r.sr_returned_date_sk = d_ret.d_date_sk                                   -- join 3
JOIN customer_demographics cd_sales
     ON s.ss_cdemo_sk = cd_sales.cd_demo_sk                                      -- join 4
JOIN customer_demographics cd_return
     ON r.sr_cdemo_sk = cd_return.cd_demo_sk                                    -- join 5
JOIN customer_address ca_sales
     ON s.ss_addr_sk = ca_sales.ca_address_sk                                    -- join 6
JOIN customer_address ca_return
     ON r.sr_addr_sk = ca_return.ca_address_sk                                   -- join 7
JOIN store_sales ss_detail
     ON r.sr_item_sk = ss_detail.ss_item_sk                                      -- join 8
JOIN date_dim d_sale2
     ON s.ss_sold_date_sk = d_sale2.d_date_sk                                    -- join 9
WHERE d_sale.d_year BETWEEN 1998 AND 2000
  AND r.sr_net_loss > 100
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_ticket_number = s.ss_ticket_number
          AND ss2.ss_quantity > 5
      )
GROUP BY
   d_sale.d_year,
   d_ret.d_year,
   ca_sales.ca_state,
   ca_return.ca_state,
   cd_sales.cd_gender,
   cd_return.cd_gender
ORDER BY net_gain DESC
LIMIT 100
