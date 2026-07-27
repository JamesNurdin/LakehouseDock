WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_brand_id,
        ca.ca_city,
        ca.ca_street_type,
        w.w_warehouse_name,
        w.w_city,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_ship_cost,
        sr.sr_return_amt_inc_tax,
        -- scalar subquery for average return amount per item
        (SELECT AVG(sr2.sr_return_amt_inc_tax)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = i.i_item_sk) AS avg_return_amt
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim dr
      ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr
      ON sr.sr_return_time_sk = tr.t_time_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_brand_id = 123
      AND ca.ca_street_type = 'Ave'
      AND w.w_city = 'Lincoln'
      AND sr.sr_return_ship_cost > 100
      AND sr.sr_return_amt_inc_tax BETWEEN 500 AND 2000
)
SELECT
    sd.ss_ticket_number,
    sd.d_date,
    sd.i_item_id,
    sd.i_product_name,
    sd.ca_city,
    sd.w_warehouse_name,
    sd.ss_quantity,
    sd.ss_net_paid,
    sd.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sd.i_item_id, sd.d_year ORDER BY sd.ss_net_profit DESC) AS profit_rank,
    sd.avg_return_amt,
    CASE WHEN sd.sr_return_ship_cost > sd.avg_return_amt THEN 'High' ELSE 'Low' END AS ship_cost_flag
FROM sales_data sd
ORDER BY profit_rank, avg_return_amt DESC
LIMIT 100
