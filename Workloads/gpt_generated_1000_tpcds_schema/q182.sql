/* goal: Identify top store‑category combinations by net profit for catalog sales that never resulted in a store return, while also showing associated store and web return losses. The query joins all 14 selected TPC‑DS tables, re‑uses date_dim and time_dim under multiple aliases, applies a CASE expression to categorize profit levels, subtracts returned orders via EXCEPT, aggregates, orders by profit and limits the output. */
WITH non_returned_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
    JOIN non_returned_orders nr ON cs.cs_order_number = nr.cs_order_number
),
sr AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
),
wr AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
)
SELECT
    d_sold.d_year,
    s.s_store_name,
    i.i_category,
    SUM(cs.cs_net_profit)                         AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)            AS orders_sold,
    SUM(sr.sr_net_loss)                           AS total_store_return_loss,
    SUM(wr.wr_net_loss)                           AS total_web_return_loss,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) >  50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                           AS profit_level
FROM cs
JOIN date_dim d_sold      ON cs.cs_sold_date_sk   = d_sold.d_date_sk          -- first date alias
JOIN date_dim d_ship      ON cs.cs_ship_date_sk   = d_ship.d_date_sk          -- second date alias
JOIN item i               ON cs.cs_item_sk        = i.i_item_sk               -- item dimension
JOIN promotion p          ON cs.cs_promo_sk       = p.p_promo_sk              -- promotion dimension
JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk       -- call center dimension
JOIN ship_mode sm         ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk        -- ship mode dimension
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk  -- billing demographic
JOIN customer_address ca_bill       ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk -- billing address
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk -- shipping demographic
JOIN customer_address ca_ship       ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk -- shipping address
JOIN sr                      ON i.i_item_sk            = sr.sr_item_sk            -- link store returns via item
JOIN store s                 ON sr.sr_store_sk         = s.s_store_sk              -- store dimension
JOIN date_dim d_return      ON sr.sr_returned_date_sk = d_return.d_date_sk         -- store‑return date alias
JOIN time_dim t_return      ON sr.sr_return_time_sk   = t_return.t_time_sk         -- store‑return time alias
JOIN reason r_sr            ON sr.sr_reason_sk        = r_sr.r_reason_sk           -- store‑return reason
JOIN wr                     ON i.i_item_sk            = wr.wr_item_sk             -- link web returns via item
JOIN date_dim d_wr_return   ON wr.wr_returned_date_sk = d_wr_return.d_date_sk     -- web‑return date alias
JOIN time_dim t_wr_return   ON wr.wr_returned_time_sk = t_wr_return.t_time_sk     -- web‑return time alias
JOIN reason r_wr            ON wr.wr_reason_sk        = r_wr.r_reason_sk           -- web‑return reason
GROUP BY d_sold.d_year, s.s_store_name, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
