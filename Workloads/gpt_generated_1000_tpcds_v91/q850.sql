/*
  Goal: Analyze profitability and return behavior for Brand#23 items sold in 2001, combining catalog and web sales, ranking items by net paid, and comparing returns per order.
*/
WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        SUM(ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ws_net_profit)        AS total_net_profit
    FROM
        web_sales
    WHERE
        ws_net_paid_inc_tax > 0
    GROUP BY
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_addr_sk,
        ws_ship_addr_sk
)
SELECT
    d_sold.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cc.cc_name,
    cp.cp_catalog_page_number,
    ws_agg.total_net_paid_inc_tax,
    ws_agg.total_net_profit,
    CASE WHEN ws_agg.total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    wr.wr_return_amt,
    -- Prior day's net paid for the same item
    LAG(ws_agg.total_net_paid_inc_tax, 1) OVER (PARTITION BY i.i_item_id ORDER BY d_sold.d_date) AS prior_day_net_paid,
    -- Rank items within the same brand by total net paid (descending)
    RANK() OVER (PARTITION BY i.i_brand ORDER BY ws_agg.total_net_paid_inc_tax DESC) AS brand_rank,
    -- Correlated subquery: total return amount for the same order, item and sold date
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_order_number = ws_agg.ws_order_number
       AND wr2.wr_item_sk = ws_agg.ws_item_sk
       AND wr2.wr_returned_date_sk = d_sold.d_date_sk) AS total_return_amount_for_order
FROM
    catalog_sales cs
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN customer_address ca_bill_cs
        ON cs.cs_bill_addr_sk = ca_bill_cs.ca_address_sk
    INNER JOIN customer_address ca_ship_cs
        ON cs.cs_ship_addr_sk = ca_ship_cs.ca_address_sk
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    INNER JOIN ws_agg
        ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
        AND ws_agg.ws_item_sk = i.i_item_sk
        AND ws_agg.ws_sold_time_sk = t_sold.t_time_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws_agg.ws_order_number
        AND wr.wr_item_sk = ws_agg.ws_item_sk
    INNER JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    INNER JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    INNER JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    INNER JOIN time_dim t_return
        ON wr.wr_returned_time_sk = t_return.t_time_sk
WHERE
    d_sold.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND ws_agg.total_net_paid_inc_tax > 1000
    AND cs.cs_quantity > 1
    AND EXISTS (
        SELECT 1
        FROM web_returns wr_sub
        WHERE wr_sub.wr_order_number = ws_agg.ws_order_number
          AND wr_sub.wr_return_amt > 500
    )
ORDER BY
    ws_agg.total_net_paid_inc_tax DESC,
    d_sold.d_date ASC
