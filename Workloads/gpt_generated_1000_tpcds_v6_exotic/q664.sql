WITH base AS (
    SELECT
        w.w_warehouse_id,
        cp.cp_department,
        r1.r_reason_desc,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT wr.wr_returned_date_sk) AS web_return_cnt,
        w.w_warehouse_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- two different customer roles for the same sales row
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    -- catalog return side
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r1
        ON cr.cr_reason_sk = r1.r_reason_sk
    JOIN catalog_page cp_ret
        ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    -- store return side (tied to the billing customer for illustration)
    JOIN store_returns sr
        ON sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    -- web return side (tied to the refunded customer from catalog return)
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r3
        ON wr.wr_reason_sk = r3.r_reason_sk
    JOIN customer_address ca_wr
        ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    -- inventory linked to the warehouse used for the sale
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'Books'
      AND w.w_state = 'CA'
    GROUP BY w.w_warehouse_id, cp.cp_department, r1.r_reason_desc, w.w_warehouse_sk
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit) * 2
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    )
)
SELECT
    b.w_warehouse_id,
    b.cp_department,
    b.r_reason_desc,
    b.total_net_profit,
    b.total_return_amount,
    b.store_return_cnt,
    b.web_return_cnt,
    RANK() OVER (ORDER BY b.total_net_profit DESC) AS profit_rank
FROM base b
ORDER BY b.total_net_profit DESC
LIMIT 100
