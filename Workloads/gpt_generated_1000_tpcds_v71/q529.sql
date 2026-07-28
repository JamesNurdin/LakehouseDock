/*
Goal: Analyze profitability and return activity for a specific brand and color of items sold during business hours, 
      segmented by item category and hour, while also considering inventory levels, customer vehicle count, and the 
      responsible call center. The query joins all 12 TPC‑DS tables, applies several realistic filters, groups and 
      aggregates key measures, uses a CASE expression to flag high‑profit categories, includes a window function to rank 
      items within each category, and limits the output to the top 100 rows.
*/
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        td.t_hour,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_color,
        c.c_customer_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        ca.ca_address_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        cs.cs_order_number,
        cs.cs_net_paid,
        cc.cc_name,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    INNER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    /* Optional left‑joined tables – may be missing for some rows */
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
       AND cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
)
SELECT
    i_category,
    i_brand,
    i_color,
    t_hour,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE WHEN SUM(ss_net_profit) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(ss_net_profit) DESC) AS profit_rank_in_category
FROM base
WHERE
    i_brand = 'Brand#12'                         -- specific brand filter
    AND i_color = 'Red'                         -- specific color filter
    AND t_hour BETWEEN 9 AND 17                 -- business hours
    AND hd_vehicle_count >= 2                  -- households with at least 2 vehicles
    AND inv_quantity_on_hand > 100             -- sufficient inventory
    AND cc_name = 'Call Center 1'               -- specific call center
GROUP BY
    i_category,
    i_brand,
    i_color,
    t_hour,
    cc_name
ORDER BY
    total_store_profit DESC
LIMIT 100
