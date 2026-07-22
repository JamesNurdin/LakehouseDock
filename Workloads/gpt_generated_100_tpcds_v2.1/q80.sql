WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_coupon_amt,
        d_cs.d_year AS d_year,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        s.s_store_name,
        inv.inv_quantity_on_hand,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ss.d_date_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE
        d_cs.d_year = 2002
        AND c.c_birth_year BETWEEN 1940 AND 1960
        AND s.s_store_name = 'cally'
        AND cs.cs_item_sk IN (73588, 265340, 131524)
        AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    d_year AS year,
    s_store_name,
    CASE WHEN c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    COUNT(DISTINCT cs_order_number) AS order_count,
    SUM(cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    AVG(cs_coupon_amt) AS avg_coupon_amount,
    SUM(cr_net_loss) AS total_catalog_return_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM joined_data
GROUP BY
    d_year,
    s_store_name,
    CASE WHEN c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END
ORDER BY
    total_net_paid_inc_ship_tax DESC,
    d_year DESC
LIMIT 100
