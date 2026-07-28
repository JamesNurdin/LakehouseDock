WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        c.c_customer_id AS c_customer_id,
        c.c_preferred_cust_flag AS c_preferred_cust_flag,
        hd.hd_buy_potential AS hd_buy_potential,
        cc.cc_name AS cc_name,
        sm.sm_ship_mode_id AS sm_ship_mode_id,
        w.w_warehouse_name AS w_warehouse_name,
        wp.wp_url AS wp_url,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid_inc_ship AS cs_net_paid_inc_ship,
        cs.cs_sales_price AS cs_sales_price,
        cs.cs_sold_time_sk AS cs_sold_time_sk,
        ss.ss_ticket_number AS ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_order_number AS ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_net_loss AS wr_net_loss,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        r.r_reason_desc AS r_reason_desc
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim tcs             ON cs.cs_sold_time_sk   = tcs.t_time_sk
    LEFT JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w             ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i                  ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer c              ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    -- Store sales linked through the same date, item and customer
    JOIN store_sales ss           ON ss.ss_sold_date_sk   = d.d_date_sk
                                   AND ss.ss_item_sk      = i.i_item_sk
                                   AND ss.ss_customer_sk  = c.c_customer_sk
    -- Optional store return (LEFT OUTER)
    LEFT JOIN store_returns sr   ON sr.sr_ticket_number   = ss.ss_ticket_number
                                   AND sr.sr_item_sk        = i.i_item_sk
                                   AND sr.sr_customer_sk    = c.c_customer_sk
                                   AND sr.sr_returned_date_sk = d.d_date_sk
    -- Web sales linked through the same date, item and customer
    JOIN web_sales ws            ON ws.ws_sold_date_sk   = d.d_date_sk
                                   AND ws.ws_item_sk        = i.i_item_sk
                                   AND ws.ws_bill_customer_sk = c.c_customer_sk
    -- Optional web return (LEFT OUTER)
    LEFT JOIN web_returns wr    ON wr.wr_order_number   = ws.ws_order_number
                                   AND wr.wr_item_sk        = i.i_item_sk
                                   AND wr.wr_returned_date_sk = d.d_date_sk
    -- Reason for store returns (LEFT OUTER, may be null)
    LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
    -- Inventory snapshot for the same date/item/warehouse
    JOIN inventory inv           ON inv.inv_date_sk   = d.d_date_sk
                                   AND inv.inv_item_sk   = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- Web page visited for the web sale
    JOIN web_page wp             ON wp.wp_web_page_sk = ws.ws_web_page_sk
                                   AND wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#45'
      AND c.c_preferred_cust_flag = 'Y'
      AND cs.cs_net_paid_inc_ship > 1000
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND sr2.sr_net_loss > 5000
      )
)
SELECT
    d_year,
    i_brand,
    i_category,
    c_customer_id,
    SUM(cs_net_paid_inc_ship) AS total_catalog_sales,
    SUM(ss_net_paid)          AS total_store_sales,
    SUM(ws_net_paid)          AS total_web_sales,
    SUM(COALESCE(sr_net_loss,0) + COALESCE(wr_net_loss,0)) AS total_returns_loss,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY SUM(cs_net_paid_inc_ship) DESC) AS brand_sales_rank
FROM base
GROUP BY
    d_year,
    i_brand,
    i_category,
    c_customer_id
ORDER BY total_catalog_sales DESC
LIMIT 100
