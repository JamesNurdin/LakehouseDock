WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        p.p_discount_active,
        w.w_warehouse_name,
        cc.cc_name,
        cc.cc_rec_start_date,
        cc.cc_rec_end_date,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        i.i_rec_start_date,
        i.i_rec_end_date
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
),
ss_join AS (
    SELECT
        ss.ss_ticket_number AS ss_order_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_quantity,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        ca.ca_state AS store_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
),
wr_join AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
)
SELECT
    b.cs_order_number,
    b.cs_sold_date_sk,
    b.i_product_name,
    b.i_category,
    b.i_brand,
    b.cs_ext_sales_price,
    b.cs_net_paid,
    b.cs_net_profit,
    ss.ss_ext_sales_price AS store_ext_sales_price,
    ss.ss_net_paid      AS store_net_paid,
    ss.ss_quantity,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY b.cs_order_number ORDER BY b.cs_net_profit DESC) AS rn_profit_rank,
    RANK()       OVER (ORDER BY b.cs_net_profit DESC)               AS global_profit_rank,
    CASE
        WHEN b.cs_net_profit > 0 THEN 'Profit'
        WHEN b.cs_net_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_category
FROM base b
LEFT JOIN ss_join ss ON b.cs_item_sk = ss.ss_item_sk AND b.cs_sold_date_sk = ss.ss_sold_date_sk
LEFT JOIN wr_join wr ON b.cs_item_sk = wr.wr_item_sk
WHERE
    b.cc_rec_start_date <= DATE '2001-01-01'               -- 1
    AND b.cc_rec_end_date   >= DATE '2001-12-31'            -- 2
    AND b.i_rec_start_date  <= DATE '2001-01-01'            -- 3
    AND b.i_rec_end_date    >= DATE '2001-12-31'            -- 4
    AND b.cs_ext_sales_price > 1000                        -- 5
    AND b.cs_net_paid        > 500                         -- 6
    AND b.i_category = 'Electronics'                       -- 7
    AND b.p_discount_active = 'Y'                          -- 8
    AND b.cc_name LIKE '%Central%'                         -- 9
ORDER BY b.cs_net_profit DESC
LIMIT 100
