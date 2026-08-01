WITH inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
base_data AS (
    SELECT
        d.d_date AS sale_date,
        i_cs.i_item_sk,
        i_cs.i_product_name,
        w_ia.w_warehouse_name,
        hd_cs_bill.hd_buy_potential AS buyer_potential,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(sr.sr_return_amt) AS total_returns,
        ia.total_qty_on_hand,
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS total_net_profit,
        CASE
            WHEN (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) > 10000 THEN 'High'
            WHEN (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                             AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        -- item dimension under different aliases
        JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
        JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
        JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
        JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
        JOIN inventory_agg ia ON ia.inv_item_sk = i_sr.i_item_sk
        JOIN item i_ia ON ia.inv_item_sk = i_ia.i_item_sk
        -- warehouse dimension under different aliases
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN warehouse w_ia ON ia.inv_warehouse_sk = w_ia.w_warehouse_sk
        -- household demographics under different aliases
        JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
        JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    WHERE
        d.d_year = 1998
    GROUP BY
        d.d_date,
        i_cs.i_item_sk,
        i_cs.i_product_name,
        w_ia.w_warehouse_name,
        hd_cs_bill.hd_buy_potential,
        ia.total_qty_on_hand
)
SELECT
    bd.sale_date,
    bd.i_item_sk,
    bd.i_product_name,
    bd.w_warehouse_name,
    bd.buyer_potential,
    bd.catalog_sales_amount,
    bd.store_sales_amount,
    bd.web_sales_amount,
    bd.total_returns,
    bd.total_qty_on_hand,
    bd.total_net_profit,
    bd.profit_category,
    ROW_NUMBER() OVER (PARTITION BY bd.sale_date ORDER BY bd.total_net_profit DESC) AS profit_rank
FROM base_data bd
ORDER BY bd.sale_date, profit_rank
LIMIT 100
