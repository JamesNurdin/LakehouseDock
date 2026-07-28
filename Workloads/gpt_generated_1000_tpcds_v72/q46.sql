WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cp.cp_department                     AS cp_department,
        p.p_promo_name,
        d_sold.d_year,
        t_sold.t_hour,
        c_bill.c_customer_id                AS bill_customer_id,
        c_ship.c_customer_id                AS ship_customer_id,
        hd_bill.hd_buy_potential,
        ib.ib_lower_bound,
        r.r_reason_desc                     AS return_reason_desc,
        ws.web_name,
        s.s_store_name,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN date_dim d_sold        ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN time_dim t_sold        ON cs.cs_sold_time_sk   = t_sold.t_time_sk
    JOIN date_dim d_ship        ON cs.cs_ship_date_sk   = d_ship.d_date_sk
    JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p            ON cs.cs_promo_sk        = p.p_promo_sk
    JOIN customer c_bill        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN income_band ib                  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s                         ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
                                         AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr            ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
    LEFT JOIN web_page wp               ON wp.wp_customer_sk = c_bill.c_customer_sk
    LEFT JOIN web_site ws               ON ws.web_open_date_sk = d_sold.d_date_sk
)
SELECT
    cp_department,
    p_promo_name,
    d_year,
    SUM(cs_net_profit)          AS total_net_profit,
    SUM(cs_ext_sales_price)     AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(cs_quantity)            AS avg_quantity,
    SUM(COALESCE(cr_return_amount, 0))     AS total_catalog_return,
    SUM(COALESCE(wr_return_amt, 0))        AS total_web_return
FROM sales_base sb
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = sb.cs_order_number
          AND cr2.cr_return_amount > 0
    )
  AND sb.d_year = 2001
GROUP BY ROLLUP (cp_department, p_promo_name, d_year)
HAVING SUM(cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
